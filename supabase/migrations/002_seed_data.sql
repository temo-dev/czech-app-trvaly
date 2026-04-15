-- ============================================================
-- Trvalý Prep — Seed Data (run AFTER 001_initial_schema.sql)
-- ============================================================

-- Add missing columns that the Flutter app reads directly off exercises rows
alter table exercises add column if not exists difficulty text not null default 'intermediate';
alter table exercises add column if not exists points     int  not null default 10;
alter table modules   add column if not exists is_locked  bool not null default false;

-- ══════════════════════════════════════════════════════════════════════════════
-- EXERCISES — 24 exercises (6 per lesson × 4 lessons)
-- content_json keys used by exercise_provider.dart:
--   prompt, explanation, correct_answer, options[]{id,text,is_correct}, audio_url
-- ══════════════════════════════════════════════════════════════════════════════

-- ── LESSON 1 (Reading) ────────────────────────────────────────────────────────

-- Block 1 — vocab fill_blank
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000001', 'fill_blank', 'vocabulary', 'beginner', 10, 10,
'{
  "prompt": "Doplňte správné slovo:\nJdu do ______ koupit chleba. (obchod / škola / nemocnice)",
  "correct_answer": "obchodu",
  "explanation": "Jdu do OBCHODU — từ ''obchod'' (cửa hàng) ở cách 2 (genitiv) là ''obchodu''."
}'::jsonb
) on conflict do nothing;

-- Block 2 — grammar MCQ
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000002', 'mcq', 'grammar', 'beginner', 10, 10,
'{
  "prompt": "Vyberte správný tvar:\nKde je ______ zastávka autobusu?",
  "explanation": "''Nejbližší'' là dạng tính từ ở số ít giống cái (feminin), đúng ngữ pháp với ''zastávka''.",
  "options": [
    {"id":"a","text":"nejbližší","is_correct":true},
    {"id":"b","text":"nejbližší","is_correct":false},
    {"id":"c","text":"nejbližší","is_correct":false},
    {"id":"d","text":"nejbližší","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 2 — grammar MCQ (fixed unique options)
update exercises set content_json = '{
  "prompt": "Vyberte správný tvar:\nKde je ______ zastávka autobusu?",
  "explanation": "''Nejbližší'' là dạng superlatif của ''blízký''. Đúng ngữ pháp với danh từ giống cái ''zastávka''.",
  "options": [
    {"id":"a","text":"nejbližší","is_correct":true},
    {"id":"b","text":"nejbližšího","is_correct":false},
    {"id":"c","text":"nejbližšímu","is_correct":false},
    {"id":"d","text":"nejbližším","is_correct":false}
  ]
}'::jsonb where id = 'e1000001-0000-0000-0000-000000000002';

-- Block 3 — reading MCQ
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000003', 'mcq', 'reading', 'intermediate', 10, 10,
'{
  "prompt": "Přečtěte si oznámení a odpovězte:\n\n📋 OZNÁMENÍ\nÚřad je otevřen v pondělí až pátek od 8:00 do 17:00. V sobotu je zavřeno.\n\nKdy je úřad otevřen?",
  "explanation": "Theo thông báo, văn phòng mở cửa từ Thứ Hai đến Thứ Sáu, 8:00–17:00. Thứ Bảy đóng cửa.",
  "options": [
    {"id":"a","text":"Pondělí až sobota, 8:00–17:00","is_correct":false},
    {"id":"b","text":"Pondělí až pátek, 8:00–17:00","is_correct":true},
    {"id":"c","text":"Každý den, 9:00–16:00","is_correct":false},
    {"id":"d","text":"Pondělí až pátek, 9:00–18:00","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 4 — listening MCQ (no real audio — prompt describes scenario)
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000004', 'mcq', 'listening', 'intermediate', 10, 10,
'{
  "prompt": "🎧 Poslouchejte a odpovězte:\n\nPan Novák říká: ''Potřebuji prodloužit povolení k pobytu. Kde mám jít?''\nÚřednice odpovídá: ''Jděte do třetího patra, kancelář číslo 12.''\n\nKam má pan Novák jít?",
  "explanation": "Nhân viên hành chính hướng dẫn ông Novák lên tầng 3, phòng số 12 để gia hạn giấy phép cư trú.",
  "options": [
    {"id":"a","text":"Do přízemí, kancelář 2","is_correct":false},
    {"id":"b","text":"Do druhého patra, kancelář 12","is_correct":false},
    {"id":"c","text":"Do třetího patra, kancelář 12","is_correct":true},
    {"id":"d","text":"Do třetího patra, kancelář 2","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 5 — speaking
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000005', 'speaking', 'speaking', 'intermediate', 10, 10,
'{
  "prompt": "Popište svůj každodenní program.\n\nVzor: Vstávám v 7 hodin. Jdu do práce autobusem...\n\nHãy mô tả thói quen hàng ngày của bạn bằng tiếng Séc (tối thiểu 3 câu).",
  "explanation": "Câu trả lời mẫu: ''Vstávám v 7 hodin. Snídám doma. Jdu do práce autobusem. Odpoledne se vracím domů a vařím večeři.''"
}'::jsonb
) on conflict do nothing;

-- Block 6 — writing
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e1000001-0000-0000-0000-000000000006', 'writing', 'writing', 'intermediate', 10, 10,
'{
  "prompt": "Napište krátký email (40–60 slov):\n\nVaše sousedka paní Horáková vám pomohla s nákupem. Napište jí e-mail s poděkováním.\n\nHãy viết email ngắn cảm ơn hàng xóm đã giúp bạn mua đồ.",
  "explanation": "Email mẫu:\nVážená paní Horáková,\nchci vám poděkovat za vaši pomoc s nákupem. Bylo to velmi milé a laskavé. Jsem vám velmi vděčný/á.\nS pozdravem, [Jméno]"
}'::jsonb
) on conflict do nothing;

-- ── LESSON 2 (Listening) ──────────────────────────────────────────────────────

-- Block 1 — vocab fill_blank
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000001', 'fill_blank', 'vocabulary', 'beginner', 10, 10,
'{
  "prompt": "Doplňte správné slovo:\nNa křižovatce zahněte ______ a pak jděte rovně. (vlevo / nahoru / dolů)",
  "correct_answer": "vlevo",
  "explanation": "VLEVO = rẽ trái. Na křižovatce zahněte VLEVO = tại ngã tư rẽ trái."
}'::jsonb
) on conflict do nothing;

-- Block 2 — grammar MCQ
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000002', 'mcq', 'grammar', 'intermediate', 10, 10,
'{
  "prompt": "Doplňte správný předložkový pád:\nAutobus odjíždí ______ nádraží.",
  "explanation": "''Z nádraží'' = từ ga (xuất phát). Předložka ''z'' + genitiv vyjadřuje výchozí místo pohybu.",
  "options": [
    {"id":"a","text":"z nádraží","is_correct":true},
    {"id":"b","text":"na nádraží","is_correct":false},
    {"id":"c","text":"do nádraží","is_correct":false},
    {"id":"d","text":"u nádraží","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 3 — reading MCQ
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000003', 'mcq', 'reading', 'intermediate', 10, 10,
'{
  "prompt": "Přečtěte a odpovězte:\n\n🚌 JÍZDNÍ ŘÁD — Linka 22\nOdjezd: 7:15, 7:45, 8:15, 8:45\nPoslední spoj: 22:15\nJízdné: 30 Kč (plné) / 15 Kč (zlevněné)\n\nKolik stojí jízdné pro studenta?",
  "explanation": "Theo bảng giờ tàu, vé ưu đãi (zlevněné) — dành cho học sinh, sinh viên — là 15 Kč.",
  "options": [
    {"id":"a","text":"30 Kč","is_correct":false},
    {"id":"b","text":"15 Kč","is_correct":true},
    {"id":"c","text":"20 Kč","is_correct":false},
    {"id":"d","text":"22 Kč","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 4 — listening MCQ
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000004', 'mcq', 'listening', 'intermediate', 10, 10,
'{
  "prompt": "🎧 Poslouchejte dialog:\n\nA: ''Promiňte, kde je nejbližší pošta?''\nB: ''Jděte rovně, pak doleva. Pošta je hned vedle banky.''\n\nKde je pošta?",
  "explanation": "Theo hội thoại: đi thẳng, rẽ trái, bưu điện nằm cạnh ngân hàng.",
  "options": [
    {"id":"a","text":"Naproti bance","is_correct":false},
    {"id":"b","text":"Vedle banky, doleva","is_correct":true},
    {"id":"c","text":"Za bankou, doprava","is_correct":false},
    {"id":"d","text":"Před bankou","is_correct":false}
  ]
}'::jsonb
) on conflict do nothing;

-- Block 5 — speaking
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000005', 'speaking', 'speaking', 'intermediate', 10, 10,
'{
  "prompt": "Popište cestu z vašeho domu na nejbližší zastávku MHD.\n\nHãy mô tả đường đi từ nhà bạn đến điểm dừng xe buýt gần nhất bằng tiếng Séc.",
  "explanation": "Câu trả lời mẫu: ''Z mého domu jdu rovně asi 5 minut. Pak zahnu doprava a zastávka je hned tam.''"
}'::jsonb
) on conflict do nothing;

-- Block 6 — writing
insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values (
'e2000001-0000-0000-0000-000000000006', 'writing', 'writing', 'intermediate', 10, 10,
'{
  "prompt": "Napište SMS zprávu (20–30 slov):\n\nZapomněli jste na schůzku s přítelem. Napište mu SMS s omluvou a navrhněte nový termín.\n\nViết tin nhắn SMS xin lỗi bạn vì đã quên cuộc hẹn và đề xuất thời gian mới.",
  "explanation": "SMS mẫu: ''Ahoj, promiň, zapomněl/a jsem na naši schůzku. Moc se omlouvám. Můžeme se setkat v pátek ve 4? [Jméno]''"
}'::jsonb
) on conflict do nothing;

-- ── LESSON 3 (Writing) ────────────────────────────────────────────────────────

insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values
('e3000001-0000-0000-0000-000000000001', 'fill_blank', 'vocabulary', 'intermediate', 10, 10,
'{
  "prompt": "Doplňte správné slovo:\nPíšu ______ svému zaměstnavateli o dovolené. (dopis / SMS / obrázek)",
  "correct_answer": "dopis",
  "explanation": "DOPIS = thư (văn bản). Khi viết cho cấp trên về nghỉ phép thì dùng ''dopis'' (thư chính thức)."
}'::jsonb),
('e3000001-0000-0000-0000-000000000002', 'mcq', 'grammar', 'intermediate', 10, 10,
'{
  "prompt": "Vyberte správné zakončení:\nVážený ______ řediteli,",
  "explanation": "Oslovení ''Vážený pane řediteli'' = Kính gửi ông Giám đốc. Đây là cách gọi lịch sự trong thư chính thức.",
  "options": [
    {"id":"a","text":"pane","is_correct":true},
    {"id":"b","text":"pan","is_correct":false},
    {"id":"c","text":"pánu","is_correct":false},
    {"id":"d","text":"pánem","is_correct":false}
  ]
}'::jsonb),
('e3000001-0000-0000-0000-000000000003', 'mcq', 'reading', 'intermediate', 10, 10,
'{
  "prompt": "Přečtěte dopis a odpovězte:\n\n''Vážená paní Nováková,\noznamuji Vám, že Vaše žádost o prodloužení pracovní smlouvy byla schválena.\nS pozdravem, Mgr. Petr Svoboda''\n\nCo bylo schváleno?",
  "explanation": "Thư thông báo rằng đơn xin gia hạn hợp đồng lao động đã được chấp thuận.",
  "options": [
    {"id":"a","text":"Žádost o dovolenou","is_correct":false},
    {"id":"b","text":"Žádost o prodloužení pracovní smlouvy","is_correct":true},
    {"id":"c","text":"Žádost o zvýšení platu","is_correct":false},
    {"id":"d","text":"Žádost o přestup na jiné oddělení","is_correct":false}
  ]
}'::jsonb),
('e3000001-0000-0000-0000-000000000004', 'mcq', 'listening', 'intermediate', 10, 10,
'{
  "prompt": "🎧 Poslouchejte a odpovězte:\n\nTajemnice říká: ''Ředitel není k dispozici do 14 hodin. Chcete zanechat zprávu nebo zavolat zpět?''\n\nCo nabízí tajemnice?",
  "explanation": "Thư ký đưa ra hai lựa chọn: để lại tin nhắn (zanechat zprávu) hoặc gọi lại (zavolat zpět).",
  "options": [
    {"id":"a","text":"Zanechat zprávu nebo počkat","is_correct":false},
    {"id":"b","text":"Zanechat zprávu nebo zavolat zpět","is_correct":true},
    {"id":"c","text":"Poslat email nebo přijít osobně","is_correct":false},
    {"id":"d","text":"Zavolat řediteli přímo","is_correct":false}
  ]
}'::jsonb),
('e3000001-0000-0000-0000-000000000005', 'speaking', 'speaking', 'intermediate', 10, 10,
'{
  "prompt": "Přečtěte si situaci a odpovězte:\n\nVoláte do firmy a chcete mluvit s ředitelem. Tajemnice říká, že není k dispozici. Co řeknete?\n\nHãy đóng vai tình huống: bạn gọi điện đến công ty và muốn nói chuyện với giám đốc.",
  "explanation": "Câu trả lời mẫu: ''Dobrý den, jmenuji se [Jméno]. Chtěl/a bych mluvit s panem ředitelem. Není k dispozici? Dobře, zanechám zprávu. Prosím, řekněte mu, že jsem volal/a a ať mi zavolá zpět na číslo 123 456 789. Děkuji.''"
}'::jsonb),
('e3000001-0000-0000-0000-000000000006', 'writing', 'writing', 'advanced', 15, 15,
'{
  "prompt": "Napište formální dopis (50–80 slov):\n\nJste zaměstnanec firmy ABC. Chcete si vzít 2 týdny dovolené v červenci. Napište žádost svému vedoucímu.\n\nViết thư xin nghỉ phép 2 tuần tháng 7 gửi cho cấp trên.",
  "explanation": "Thư mẫu:\nVážený pane vedoucí,\ndovolte mi požádat o 2 týdny dovolené od 1. do 14. července. Všechny moje úkoly budou splněny před odchodem.\nDěkuji za pochopení.\nS pozdravem, [Jméno]"
}'::jsonb)
on conflict do nothing;

-- ── LESSON 4 (Speaking) ───────────────────────────────────────────────────────

insert into exercises (id, type, skill, difficulty, points, xp_reward, content_json) values
('e4000001-0000-0000-0000-000000000001', 'fill_blank', 'vocabulary', 'beginner', 10, 10,
'{
  "prompt": "Doplňte správné slovo:\nJmenuji se Pavel. Jsem ______ z Vietnamu. (Vietnamec / Česk / Slovák)",
  "correct_answer": "Vietnamec",
  "explanation": "VIETNAMEC = người Việt Nam (nam giới). Jmenuji se... Jsem Vietnamec = Tôi tên là... Tôi là người Việt Nam."
}'::jsonb),
('e4000001-0000-0000-0000-000000000002', 'mcq', 'grammar', 'beginner', 10, 10,
'{
  "prompt": "Vyberte správný tvar slovesa ''být'':\nJá ______ student.",
  "explanation": "Với chủ ngữ ''já'' (tôi), động từ ''být'' chia là ''jsem''. Já jsem student = Tôi là sinh viên.",
  "options": [
    {"id":"a","text":"jsem","is_correct":true},
    {"id":"b","text":"jsi","is_correct":false},
    {"id":"c","text":"je","is_correct":false},
    {"id":"d","text":"jsou","is_correct":false}
  ]
}'::jsonb),
('e4000001-0000-0000-0000-000000000003', 'mcq', 'reading', 'beginner', 10, 10,
'{
  "prompt": "Přečtěte vizitku a odpovězte:\n\n👤 Ing. Jana Procházková\n📧 jana.prochazkova@firma.cz\n📞 +420 777 123 456\n🏢 Manažerka projektu, Firma s.r.o.\n\nJaká je profese Jany Procházkové?",
  "explanation": "Theo danh thiếp, Jana Procházková là Manažerka projektu (Quản lý dự án) tại Firma s.r.o.",
  "options": [
    {"id":"a","text":"Účetní","is_correct":false},
    {"id":"b","text":"Manažerka projektu","is_correct":true},
    {"id":"c","text":"Ředitelka","is_correct":false},
    {"id":"d","text":"Sekretářka","is_correct":false}
  ]
}'::jsonb),
('e4000001-0000-0000-0000-000000000004', 'mcq', 'listening', 'beginner', 10, 10,
'{
  "prompt": "🎧 Poslouchejte a odpovězte:\n\nA: ''Dobrý den, jak se jmenujete?''\nB: ''Dobrý den, jmenuji se Nguyen Van An. Jsem z Vietnamu a pracuji jako kuchař.''\n\nCo dělá pan Nguyen?",
  "explanation": "Ông Nguyen tự giới thiệu: Jsem z Vietnamu a pracuji jako kuchař = Tôi là người Việt Nam và làm đầu bếp.",
  "options": [
    {"id":"a","text":"Je učitel","is_correct":false},
    {"id":"b","text":"Je kuchař","is_correct":true},
    {"id":"c","text":"Je řidič","is_correct":false},
    {"id":"d","text":"Je lékař","is_correct":false}
  ]
}'::jsonb),
('e4000001-0000-0000-0000-000000000005', 'speaking', 'speaking', 'beginner', 10, 10,
'{
  "prompt": "Představte se česky.\n\nŘekněte:\n• Jméno a příjmení\n• Odkud jste\n• Co děláte (práce / studium)\n• Jak dlouho žijete v ČR\n\nHãy tự giới thiệu bản thân bằng tiếng Séc (tối thiểu 4 câu).",
  "explanation": "Câu trả lời mẫu: ''Dobrý den, jmenuji se Nguyen Thi Lan. Jsem z Vietnamu. Pracuji jako prodavačka. V České republice žiji 5 let.''"
}'::jsonb),
('e4000001-0000-0000-0000-000000000006', 'writing', 'writing', 'beginner', 10, 10,
'{
  "prompt": "Napište krátký text o sobě (30–50 slov):\n\nVyplňte dotazník — napište o sobě: jméno, původ, zaměstnání, záliby.\n\nViết đoạn giới thiệu bản thân ngắn: tên, quê quán, nghề nghiệp, sở thích.",
  "explanation": "Văn mẫu: ''Jmenuji se Tran Van Minh. Jsem z Vietnamu, ale žiji v Praze. Pracuji v restauraci. Ve volném čase rád hraji fotbal a čtu knihy.''"
}'::jsonb)
on conflict do nothing;


-- ══════════════════════════════════════════════════════════════════════════════
-- LESSON BLOCKS — link lessons to exercises (6 blocks per lesson)
-- ══════════════════════════════════════════════════════════════════════════════

-- Lesson 1 (Reading)
insert into lesson_blocks (id, lesson_id, type, exercise_id, order_index) values
('b1000001-0000-0000-0000-000000000001','00000000-0000-0000-0011-000000000001','vocab',     'e1000001-0000-0000-0000-000000000001', 1),
('b1000001-0000-0000-0000-000000000002','00000000-0000-0000-0011-000000000001','grammar',   'e1000001-0000-0000-0000-000000000002', 2),
('b1000001-0000-0000-0000-000000000003','00000000-0000-0000-0011-000000000001','reading',   'e1000001-0000-0000-0000-000000000003', 3),
('b1000001-0000-0000-0000-000000000004','00000000-0000-0000-0011-000000000001','listening', 'e1000001-0000-0000-0000-000000000004', 4),
('b1000001-0000-0000-0000-000000000005','00000000-0000-0000-0011-000000000001','speaking',  'e1000001-0000-0000-0000-000000000005', 5),
('b1000001-0000-0000-0000-000000000006','00000000-0000-0000-0011-000000000001','writing',   'e1000001-0000-0000-0000-000000000006', 6)
on conflict do nothing;

-- Lesson 2 (Listening)
insert into lesson_blocks (id, lesson_id, type, exercise_id, order_index) values
('b2000001-0000-0000-0000-000000000001','00000000-0000-0000-0022-000000000001','vocab',     'e2000001-0000-0000-0000-000000000001', 1),
('b2000001-0000-0000-0000-000000000002','00000000-0000-0000-0022-000000000001','grammar',   'e2000001-0000-0000-0000-000000000002', 2),
('b2000001-0000-0000-0000-000000000003','00000000-0000-0000-0022-000000000001','reading',   'e2000001-0000-0000-0000-000000000003', 3),
('b2000001-0000-0000-0000-000000000004','00000000-0000-0000-0022-000000000001','listening', 'e2000001-0000-0000-0000-000000000004', 4),
('b2000001-0000-0000-0000-000000000005','00000000-0000-0000-0022-000000000001','speaking',  'e2000001-0000-0000-0000-000000000005', 5),
('b2000001-0000-0000-0000-000000000006','00000000-0000-0000-0022-000000000001','writing',   'e2000001-0000-0000-0000-000000000006', 6)
on conflict do nothing;

-- Lesson 3 (Writing)
insert into lesson_blocks (id, lesson_id, type, exercise_id, order_index) values
('b3000001-0000-0000-0000-000000000001','00000000-0000-0000-0033-000000000001','vocab',     'e3000001-0000-0000-0000-000000000001', 1),
('b3000001-0000-0000-0000-000000000002','00000000-0000-0000-0033-000000000001','grammar',   'e3000001-0000-0000-0000-000000000002', 2),
('b3000001-0000-0000-0000-000000000003','00000000-0000-0000-0033-000000000001','reading',   'e3000001-0000-0000-0000-000000000003', 3),
('b3000001-0000-0000-0000-000000000004','00000000-0000-0000-0033-000000000001','listening', 'e3000001-0000-0000-0000-000000000004', 4),
('b3000001-0000-0000-0000-000000000005','00000000-0000-0000-0033-000000000001','speaking',  'e3000001-0000-0000-0000-000000000005', 5),
('b3000001-0000-0000-0000-000000000006','00000000-0000-0000-0033-000000000001','writing',   'e3000001-0000-0000-0000-000000000006', 6)
on conflict do nothing;

-- Lesson 4 (Speaking)
insert into lesson_blocks (id, lesson_id, type, exercise_id, order_index) values
('b4000001-0000-0000-0000-000000000001','00000000-0000-0000-0044-000000000001','vocab',     'e4000001-0000-0000-0000-000000000001', 1),
('b4000001-0000-0000-0000-000000000002','00000000-0000-0000-0044-000000000001','grammar',   'e4000001-0000-0000-0000-000000000002', 2),
('b4000001-0000-0000-0000-000000000003','00000000-0000-0000-0044-000000000001','reading',   'e4000001-0000-0000-0000-000000000003', 3),
('b4000001-0000-0000-0000-000000000004','00000000-0000-0000-0044-000000000001','listening', 'e4000001-0000-0000-0000-000000000004', 4),
('b4000001-0000-0000-0000-000000000005','00000000-0000-0000-0044-000000000001','speaking',  'e4000001-0000-0000-0000-000000000005', 5),
('b4000001-0000-0000-0000-000000000006','00000000-0000-0000-0044-000000000001','writing',   'e4000001-0000-0000-0000-000000000006', 6)
on conflict do nothing;


-- ══════════════════════════════════════════════════════════════════════════════
-- DEMO USERS for leaderboard (fake UUIDs — no auth entry, display only)
-- Drop FK so we can insert demo rows without real profiles
-- ══════════════════════════════════════════════════════════════════════════════

alter table leaderboard_weekly drop constraint if exists leaderboard_weekly_user_id_fkey;

insert into leaderboard_weekly (user_id, display_name, weekly_xp, week_start)
select
  gen_random_uuid(),
  display_name,
  weekly_xp,
  date_trunc('week', now())::date
from (values
  ('Nguyễn Thị Lan',   420),
  ('Trần Văn Minh',    380),
  ('Phạm Thu Hà',      340),
  ('Lê Quốc Bảo',     295),
  ('Hoàng Yến Nhi',   260),
  ('Vũ Đình Long',     210),
  ('Đặng Thị Mai',     185),
  ('Bùi Thanh Tùng',  150),
  ('Ngô Minh Châu',   120),
  ('Đinh Thị Hoa',     90)
) as t(display_name, weekly_xp)
on conflict do nothing;


-- ══════════════════════════════════════════════════════════════════════════════
-- TEACHER REVIEWS — sample feedback threads (for teacher inbox testing)
-- These will be linked to the first real user who signs up via a trigger,
-- OR you can manually update user_id after signing up.
-- For now we insert with a placeholder — update after first signup.
-- ══════════════════════════════════════════════════════════════════════════════

-- Run this AFTER your first signup to attach sample reviews to your account:
-- UPDATE teacher_reviews SET user_id = auth.uid() WHERE user_id IS NULL;
-- (Or replace the NULL with your actual UUID from the profiles table)

-- We use a DO block so it only inserts if no reviews exist yet
do $$
begin
  if not exists (select 1 from teacher_reviews limit 1) then
    insert into teacher_reviews (id, user_id, skill, status, preview_text, unread_count, created_at)
    -- Note: user_id is nullable in our schema (references profiles on delete set null)
    -- These will show up once you run the UPDATE statement above
    values
    (
      'tr000001-0000-0000-0000-000000000001',
      null,
      'writing',
      'reviewed',
      'Email của bạn có cấu trúc tốt. Cần chú ý thêm về cách dùng cách 4 (akuzativ).',
      2,
      now() - interval '2 days'
    ),
    (
      'tr000001-0000-0000-0000-000000000002',
      null,
      'speaking',
      'pending',
      'Đang chờ giáo viên xem xét bài nói của bạn...',
      0,
      now() - interval '1 day'
    );

    insert into teacher_comments (review_id, body, is_teacher, author_name, created_at) values
    (
      'tr000001-0000-0000-0000-000000000001',
      'Xin chào! Tôi đã xem bài viết email của bạn.',
      true,
      'Mgr. Jana Horáková',
      now() - interval '2 days' + interval '1 hour'
    ),
    (
      'tr000001-0000-0000-0000-000000000001',
      'Cấu trúc email rất tốt. Tuy nhiên, cần chú ý: "Vážený pane" + tên chức vụ ở cách 5 (vokativ). Ví dụ: "Vážený pane řediteli" (không phải "ředitel").',
      true,
      'Mgr. Jana Horáková',
      now() - interval '2 days' + interval '2 hours'
    ),
    (
      'tr000001-0000-0000-0000-000000000001',
      'Cảm ơn cô đã nhận xét! Tôi sẽ luyện thêm về cách 5.',
      false,
      null,
      now() - interval '1 day'
    );
  end if;
end $$;


-- ══════════════════════════════════════════════════════════════════════════════
-- HELPER: after first signup, run this to attach data to your account
-- Copy your user UUID from Supabase Auth → Users, then run:
--
-- UPDATE teacher_reviews SET user_id = '<your-uuid>' WHERE user_id IS NULL;
-- UPDATE leaderboard_weekly SET display_name = 'Bạn (Test)'
--   WHERE user_id = (SELECT id FROM profiles ORDER BY created_at LIMIT 1);
-- ══════════════════════════════════════════════════════════════════════════════
