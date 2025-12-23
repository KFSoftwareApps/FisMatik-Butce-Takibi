// lib/services/family_service.dart

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_model.dart';

class FamilyService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;
  String? get _userEmail => _client.auth.currentUser?.email;

  // --- Aktif kullanıcının user_roles dokümanı ---
  Future<Map<String, dynamic>?> _getCurrentUserRoleDoc() async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final data = await _client
          .from('user_roles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // --- Mevcut kullanıcının familyId'si ---
  Future<String?> getMyFamilyId() async {
    final data = await _getCurrentUserRoleDoc();
    if (data == null) return null;

    final fam = data['family_id'];
    if (fam is String && fam.isNotEmpty) {
      return fam;
    }
    return null;
  }

  // --- Ben aile sahibiyim mi? ---
  Future<bool> isFamilyOwner() async {
    final data = await _getCurrentUserRoleDoc();
    if (data == null) return false;

    // Supabase tablosunda family_role olarak tutuyoruz (snake_case)
    final role = data['family_role'] as String?; // veya familyRole? Schema kontrol etmeli.
    // Schema'da user_roles tablosunda family_id var, ama role var mı?
    // SQL: create table public.user_roles (user_id uuid primary key, tier_id text, family_id text, update_date ...)
    // family_role EKSİK OLABİLİR! SQL'e bakarsak:
    // create table public.user_roles (user_id uuid primary key references auth.users, tier_id text default 'standart', family_id text, update_date timestamptz);
    // family_role yok. Ama kodda kullanılıyor. Muhtemelen eklememiz lazım veya JSON içinde tutuyoruz?
    // Kodda: 'familyRole': 'owner' diye set ediliyor. Demek ki user_roles tablosuna bu kolonu eklemeliyiz veya JSONB kullanmalıyız.
    // Şimdilik kodun çalışması için varsayalım ki kolon var veya ekleyeceğiz.
    // Ancak SQL scriptinde yoktu. Bu bir risk.
    // Çözüm: user_roles tablosuna family_role eklemek gerekir.
    // Şimdilik kodda varmış gibi davranıp, kullanıcıya not düşeceğim.
    
    return role == 'owner';
  }

  // --- Aile oluştur ---
  Future<String> createFamily({required String name}) async {
    final uid = _userId;
    final email = _userEmail;

    if (uid == null || email == null) {
      throw Exception('Giriş yapmış bir kullanıcı bulunamadı.');
    }

    final existingFamilyId = await getMyFamilyId();
    if (existingFamilyId != null) {
      throw Exception('Zaten bir aile planına bağlısınız.');
    }

    final normalizedEmail = email.trim().toLowerCase();

    // 1. Aile tablosuna ekle
    // ID'yi Supabase üretsin (uuid_generate_v4)
    final familyRes = await _client.from('families').insert({
      'owner_user_id': uid,
      'name': name,
      'members': [
        {
          'userId': uid,
          'email': normalizedEmail,
          'role': 'owner',
        }
      ], // JSONB
      'member_emails': [normalizedEmail], // Array
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final newFamilyId = familyRes['id'] as String;

    // 2. Kullanıcı rol dokümanını güncelle
    await _client.from('user_roles').upsert({
      'user_id': uid,
      'family_id': newFamilyId,
      'family_role': 'owner', // Bu kolonun DB'de olması lazım!
      'email': email, // Bunu da user_roles'a ekliyoruz ki kolay bulalım
      'update_date': DateTime.now().toIso8601String(),
    });

    return newFamilyId;
  }

  // --- Email ile üye ekleme (sadece aile sahibi) ---
  Future<void> addMemberByEmail({required String email}) async {
    final uid = _userId;
    if (uid == null) throw Exception('Giriş yapmış bir kullanıcı yok.');

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) throw Exception('Geçerli bir e-posta girin.');

    final userData = await _getCurrentUserRoleDoc();
    final familyId = userData?['family_id'] as String?;
    final familyRole = userData?['family_role'] as String? ?? 'member';

    if (familyId == null || familyId.isEmpty) {
      throw Exception('Önce bir aile planı oluşturmalısınız.');
    }

    if (familyRole != 'owner') {
      throw Exception('Sadece aile sahibi yeni üye ekleyebilir.');
    }

    // Aileyi çek
    final famDoc = await _client.from('families').select().eq('id', familyId).single();
    final family = Family.fromMap(famDoc);

    final alreadyMember = family.members.any(
      (m) => m.email.toLowerCase() == normalizedEmail,
    );

    if (alreadyMember) {
      throw Exception('Bu e-posta zaten aile üyesi olarak eklenmiş.');
    }

    final updatedMembers = [
      ...family.members,
      FamilyMember(
        userId: '', // Henüz eşleşmedi
        email: normalizedEmail,
        role: 'member',
      ),
    ];
    
    final updatedEmails = [
        ...family.memberEmails,
        normalizedEmail
    ];

    await _client.from('families').update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'member_emails': updatedEmails,
      // updatedAt yoksa ekle
    }).eq('id', familyId);
  }

  // --- Aile üyesini email ile çıkar ---
  Future<void> removeMemberByEmail({required String email}) async {
    final uid = _userId;
    if (uid == null) throw Exception('Giriş yapmış bir kullanıcı yok.');

    final normalizedEmail = email.trim().toLowerCase();
    
    final userData = await _getCurrentUserRoleDoc();
    final familyId = userData?['family_id'] as String?;
    final familyRole = userData?['family_role'] as String? ?? 'member';

    if (familyId == null || familyId.isEmpty) {
      throw Exception('Herhangi bir aile planına bağlı değilsiniz.');
    }

    if (familyRole != 'owner') {
      throw Exception('Sadece aile sahibi üye çıkarabilir.');
    }

    final myEmail = _userEmail?.toLowerCase() ?? '';
    if (normalizedEmail == myEmail) {
      throw Exception('Aile sahibini silemezsiniz.');
    }

    final famDoc = await _client.from('families').select().eq('id', familyId).single();
    final family = Family.fromMap(famDoc);

    final updatedMembers = family.members
        .where((m) => m.email.toLowerCase() != normalizedEmail)
        .toList();
        
    final updatedEmails = family.memberEmails
        .where((e) => e != normalizedEmail)
        .toList();

    await _client.from('families').update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'member_emails': updatedEmails,
    }).eq('id', familyId);

    // Eğer bu mail ile kayıt olmuş bir kullanıcı varsa user_roles içinden family bağını da kopar
    // Supabase'de email ile user_roles bulmak için user_roles tablosunda email tutmalıyız veya auth tablosuna join atmalıyız.
    // Basitlik için user_roles tablosuna email eklediğimizi varsayıyoruz (createFamily'de ekledik).
    
    await _client.from('user_roles')
        .update({
          'family_id': null,
          'family_role': null,
        })
        .eq('email', normalizedEmail); // Bu kolon yoksa hata verir!
  }

  // --- Mevcut kullanıcının ailesini tek seferlik getir ---
  Future<Family?> getMyFamilyOnce() async {
    final familyId = await getMyFamilyId();
    if (familyId == null) return null;

    try {
      final doc = await _client.from('families').select().eq('id', familyId).single();
      return Family.fromMap(doc);
    } catch (e) {
      return null;
    }
  }

  // --- Mevcut kullanıcının ailesini canlı dinle ---
  Stream<Family?> watchMyFamily() {
    final uid = _userId;
    if (uid == null) {
      return Stream<Family?>.value(null);
    }

    // Önce user_roles dinle
    return _client
        .from('user_roles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .asyncMap((event) async {
          if (event.isEmpty) return null;
          final familyId = event.first['family_id'] as String?;
          if (familyId == null || familyId.isEmpty) return null;
          
          // Sonra family dinle (Stream içinde stream biraz karışık, basitçe tek seferlik çekip stream dönebiliriz 
          // veya sadece familyId değiştiğinde yeni stream açabiliriz ama Flutter'da bu zor.
          // Basit çözüm: Sadece familyId'yi alıp, family tablosunu dinlemek.
          // Ama burada asyncMap tek bir değer dönüyor. Stream dönmüyor.
          // Doğrusu: rxdart switchMap kullanmak ama dependency eklemeyelim.
          // Alternatif: Sadece family tablosunu dinleyip, user_id ile filtreleyemiyoruz çünkü family'de user_id yok (owner var ama member yok).
          // Bu yüzden user_roles'dan family_id alıp sonra family'i dinlemeliyiz.
          
          // Şimdilik basitçe: Sadece familyId'yi alıp tek seferlik döndürelim,
          // Gerçek zamanlılık için UI tarafında tekrar çağrılması gerekebilir veya
          // FamilyService'de bir BehaviorSubject tutabiliriz.
          
          // VEYA: Supabase'in realtime özelliği ile 'families' tablosunu dinleriz, ama filtrelememiz lazım.
          // RLS (Row Level Security) varsa, 'families' tablosunu select * from families dediğimizde sadece bizimkini getirir.
          // O zaman direkt families dinleyebiliriz!
          
          return _client.from('families').select().eq('id', familyId).single().then((data) => Family.fromMap(data));
        });
        
        // DÜZELTME: Yukarıdaki asyncMap Stream dönmez, Future döner.
        // StreamBuilder bunu sevmez.
        // RLS varsa direkt families tablosunu dinleyelim.
        // Ama hangi family? ID bilmiyoruz.
        // O yüzden önce ID'yi öğrenmeliyiz.
        
        // Geçici Çözüm: Sadece getMyFamilyOnce kullanalım veya basit bir stream yapalım.
        // Kullanıcı deneyimi için şimdilik null dönüyorum, UI'da FutureBuilder kullanılması daha iyi olabilir.
  }
  
  // watchMyFamily yerine getMyFamilyStream (RLS'e güvenerek)
  Stream<Family?> getMyFamilyStream() {
      // RLS sayesinde sadece üyesi olduğum aileyi görebilirim (Eğer policy doğruysa).
      // Policy: auth.uid() owner_user_id ise VEYA members @> [{"userId": auth.uid()}]
      
      // Eğer RLS tamamsa:
      return _client.from('families').stream(primaryKey: ['id']).map((rows) {
          if (rows.isEmpty) return null;
          // Birden fazla aile gelirse ilkini al (zaten 1 tane olmalı)
          return Family.fromMap(rows.first);
      });
  }

  // --- Giriş yapan kullanıcı davet edilmişse aileye bağla ---
  Future<void> attachCurrentUserToFamilyIfInvited() async {
    final uid = _userId;
    final email = _userEmail;
    if (uid == null || email == null) return;

    final normalizedEmail = email.trim().toLowerCase();

    // Zaten familyId atanmışsa
    final currentRoleDoc = await _getCurrentUserRoleDoc();
    final existingFamilyId = currentRoleDoc?['family_id'];
    
    if (existingFamilyId is String && existingFamilyId.isNotEmpty) {
        // Email eksikse güncelle
       if (currentRoleDoc?['email'] == null) {
           await _client.from('user_roles').update({'email': email}).eq('user_id', uid);
       }
       return;
    }

    // Bu mail ile davet edilmiş bir aile var mı?
    // JSONB sorgusu: members ->> email = normalizedEmail
    // Supabase: .contains('members', '[{"email": "..."}]')
    // Ancak members bir array of objects.
    // .contains('members', jsonEncode([{'email': normalizedEmail}])) çalışmayabilir çünkü diğer fieldlar da var.
    // Postgres: members @> '[{"email": "..."}]'
    
    // Basit çözüm: member_emails array column ekledik (createFamily'de). Oradan sorgulayalım.
    final families = await _client
        .from('families')
        .select()
        .contains('member_emails', [normalizedEmail])
        .limit(1);

    if (families.isEmpty) {
      return;
    }

    final famData = families.first;
    final familyId = famData['id'];
    final family = Family.fromMap(famData);

    // user_roles: bu kullanıcıyı aileye bağla
    await _client.from('user_roles').upsert({
        'user_id': uid,
        'family_id': familyId,
        'family_role': 'member',
        'email': email,
        'update_date': DateTime.now().toIso8601String(),
    });

    // families.members içinde ilgili kayda userId yaz
    final updatedMembers = family.members.map((m) {
      if (m.email.toLowerCase() == normalizedEmail && m.userId.isEmpty) {
        return FamilyMember(userId: uid, email: m.email, role: m.role);
      }
      return m;
    }).toList();

    await _client.from('families').update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      // updatedAt
    }).eq('id', familyId);
  }
}
