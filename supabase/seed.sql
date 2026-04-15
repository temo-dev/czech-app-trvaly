-- =============================================================================
-- Trvalý Prep — seed.sql
-- Structural mock data — chạy bất kỳ lúc nào (không cần user đã đăng ký)
-- Chạy trong: Supabase Dashboard → SQL Editor → New query → Paste → Run
-- =============================================================================
-- Lưu ý: file này idempotent (ON CONFLICT DO NOTHING) — chạy nhiều lần OK


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN A — EXERCISES (24 rows: 6 blocks × 4 lessons)
-- Columns thực tế: id, type, skill, xp_reward, content_json, asset_urls
-- ═════════════════════════════════════════════════════════════════════════════

-- ── Lesson 1: Đọc biển hiệu và thông báo (Reading) ──────────────────────────

INSERT INTO exercises (id, type, skill, xp_reward, content_json) VALUES
(
  'e1000001-0000-0000-0000-000000000001',
  'fill_blank', 'vocabulary', 10,
  '{
    "prompt": "Doplňte správné slovo:\nJdu do ______ koupit chleba.\n(obchod / škola / nemocnice)",
    "correct_answer": "obchodu",
    "explanation": "OBCHODU — từ ''obchod'' (cửa hàng) ở cách 2 (genitiv). Jdu do + genitiv."
  }'
),
(
  'e1000001-0000-0000-0000-000000000002',
  'mcq', 'grammar', 10,
  '{
    "prompt": "Vyberte správný tvar:\nKde je ______ zastávka autobusu?",
    "explanation": "NEJBLIŽŠÍ — dạng tính từ siêu cấp của blízký, phù hợp với danh từ giống cái zastávka.",
    "options": [
      {"id": "a", "text": "nejbližší",   "is_correct": true},
      {"id": "b", "text": "nejbližšího", "is_correct": false},
      {"id": "c", "text": "nejbližšímu", "is_correct": false},
      {"id": "d", "text": "nejbližším",  "is_correct": false}
    ]
  }'
),
(
  'e1000001-0000-0000-0000-000000000003',
  'mcq', 'reading', 10,
  '{
    "prompt": "Přečtěte si oznámení a odpovězte:\n\n📋 OZNÁMENÍ\nÚřad je otevřen v pondělí až pátek od 8:00 do 17:00.\nV sobotu je zavřeno.\n\nKdy je úřad otevřen?",
    "explanation": "Văn phòng mở cửa Thứ Hai đến Thứ Sáu, 8:00–17:00. Thứ Bảy đóng cửa.",
    "options": [
      {"id": "a", "text": "Pondělí až sobota, 8:00–17:00",  "is_correct": false},
      {"id": "b", "text": "Pondělí až pátek, 8:00–17:00",   "is_correct": true},
      {"id": "c", "text": "Každý den, 9:00–16:00",           "is_correct": false},
      {"id": "d", "text": "Pondělí až pátek, 9:00–18:00",   "is_correct": false}
    ]
  }'
),
(
  'e1000001-0000-0000-0000-000000000004',
  'mcq', 'listening', 10,
  '{
    "prompt": "🎧 [Poslech]\nPan Novák: ''Potřebuji prodloužit povolení k pobytu. Kde mám jít?''\nÚřednice: ''Jděte do třetího patra, kancelář číslo 12.''\n\nKam má pan Novák jít?",
    "explanation": "Nhân viên hướng dẫn ông Novák lên tầng 3, phòng số 12 để gia hạn giấy phép cư trú.",
    "options": [
      {"id": "a", "text": "Do přízemí, kancelář 2",          "is_correct": false},
      {"id": "b", "text": "Do druhého patra, kancelář 12",   "is_correct": false},
      {"id": "c", "text": "Do třetího patra, kancelář 12",   "is_correct": true},
      {"id": "d", "text": "Do třetího patra, kancelář 2",    "is_correct": false}
    ]
  }'
),
(
  'e1000001-0000-0000-0000-000000000005',
  'speaking', 'speaking', 10,
  '{
    "prompt": "Popište svůj každodenní program.\n\nVzor: Vstávám v 7 hodin. Jdu do práce autobusem...\n\nHãy mô tả thói quen hàng ngày của bạn bằng tiếng Séc (tối thiểu 3 câu).",
    "explanation": "Mẫu: Vstávám v 7 hodin. Snídám doma. Jdu do práce autobusem. Odpoledne se vracím domů."
  }'
),
(
  'e1000001-0000-0000-0000-000000000006',
  'writing', 'writing', 10,
  '{
    "prompt": "Napište krátký email (40–60 slov):\n\nVaše sousedka paní Horáková vám pomohla s nákupem. Napište jí email s poděkováním.\n\nHãy viết email ngắn cảm ơn hàng xóm đã giúp bạn mua đồ.",
    "explanation": "Mẫu:\nVážená paní Horáková,\nchci vám poděkovat za vaši pomoc s nákupem. Bylo to velmi milé.\nS pozdravem, [Jméno]"
  }'
)
ON CONFLICT DO NOTHING;

-- ── Lesson 2: Nghe chỉ đường (Listening) ────────────────────────────────────

INSERT INTO exercises (id, type, skill, xp_reward, content_json) VALUES
(
  'e2000001-0000-0000-0000-000000000001',
  'fill_blank', 'vocabulary', 10,
  '{
    "prompt": "Doplňte správné slovo:\nNa křižovatce zahněte ______ a pak jděte rovně.\n(vlevo / nahoru / dolů)",
    "correct_answer": "vlevo",
    "explanation": "VLEVO = rẽ trái. Na křižovatce zahněte VLEVO = tại ngã tư rẽ trái."
  }'
),
(
  'e2000001-0000-0000-0000-000000000002',
  'mcq', 'grammar', 10,
  '{
    "prompt": "Doplňte správný předložkový pád:\nAutobus odjíždí ______ nádraží.",
    "explanation": "Z nádraží = từ ga (xuất phát). Předložka z + genitiv vyjadřuje výchozí místo pohybu.",
    "options": [
      {"id": "a", "text": "z nádraží",  "is_correct": true},
      {"id": "b", "text": "na nádraží", "is_correct": false},
      {"id": "c", "text": "do nádraží", "is_correct": false},
      {"id": "d", "text": "u nádraží",  "is_correct": false}
    ]
  }'
),
(
  'e2000001-0000-0000-0000-000000000003',
  'mcq', 'reading', 10,
  '{
    "prompt": "Přečtěte a odpovězte:\n\n🚌 JÍZDNÍ ŘÁD — Linka 22\nOdjezd: 7:15, 7:45, 8:15, 8:45\nPoslední spoj: 22:15\nJízdné: 30 Kč (plné) / 15 Kč (zlevněné)\n\nKolik stojí jízdné pro studenta?",
    "explanation": "Vé ưu đãi (zlevněné) dành cho sinh viên là 15 Kč.",
    "options": [
      {"id": "a", "text": "30 Kč", "is_correct": false},
      {"id": "b", "text": "15 Kč", "is_correct": true},
      {"id": "c", "text": "20 Kč", "is_correct": false},
      {"id": "d", "text": "22 Kč", "is_correct": false}
    ]
  }'
),
(
  'e2000001-0000-0000-0000-000000000004',
  'mcq', 'listening', 10,
  '{
    "prompt": "🎧 [Poslech]\nA: ''Promiňte, kde je nejbližší pošta?''\nB: ''Jděte rovně, pak doleva. Pošta je hned vedle banky.''\n\nKde je pošta?",
    "explanation": "Đi thẳng, rẽ trái, bưu điện nằm cạnh ngân hàng.",
    "options": [
      {"id": "a", "text": "Naproti bance",        "is_correct": false},
      {"id": "b", "text": "Vedle banky, doleva",  "is_correct": true},
      {"id": "c", "text": "Za bankou, doprava",   "is_correct": false},
      {"id": "d", "text": "Před bankou",           "is_correct": false}
    ]
  }'
),
(
  'e2000001-0000-0000-0000-000000000005',
  'speaking', 'speaking', 10,
  '{
    "prompt": "Popište cestu z vašeho domu na nejbližší zastávku MHD.\n\nHãy mô tả đường đi từ nhà bạn đến điểm dừng xe buýt gần nhất bằng tiếng Séc.",
    "explanation": "Mẫu: Z mého domu jdu rovně asi 5 minut. Pak zahnu doprava a zastávka je hned tam."
  }'
),
(
  'e2000001-0000-0000-0000-000000000006',
  'writing', 'writing', 10,
  '{
    "prompt": "Napište SMS zprávu (20–30 slov):\n\nZapomněli jste na schůzku s přítelem. Napište mu SMS s omluvou a navrhněte nový termín.\n\nViết tin nhắn SMS xin lỗi bạn vì đã quên cuộc hẹn.",
    "explanation": "Mẫu: Ahoj, promiň, zapomněl/a jsem na naši schůzku. Moc se omlouvám. Můžeme se setkat v pátek ve 4? [Jméno]"
  }'
)
ON CONFLICT DO NOTHING;

-- ── Lesson 3: Viết email xin việc (Writing) ─────────────────────────────────

INSERT INTO exercises (id, type, skill, xp_reward, content_json) VALUES
(
  'e3000001-0000-0000-0000-000000000001',
  'fill_blank', 'vocabulary', 10,
  '{
    "prompt": "Doplňte správné slovo:\nPíšu ______ svému zaměstnavateli o dovolené.\n(dopis / SMS / obrázek)",
    "correct_answer": "dopis",
    "explanation": "DOPIS = thư (văn bản chính thức). Khi viết cho cấp trên về nghỉ phép thì dùng dopis."
  }'
),
(
  'e3000001-0000-0000-0000-000000000002',
  'mcq', 'grammar', 10,
  '{
    "prompt": "Vyberte správné zakončení:\nVážený ______ řediteli,",
    "explanation": "PANE — oslovení Vážený pane řediteli = Kính gửi ông Giám đốc. Cách gọi lịch sự trong thư chính thức.",
    "options": [
      {"id": "a", "text": "pane",  "is_correct": true},
      {"id": "b", "text": "pan",   "is_correct": false},
      {"id": "c", "text": "pánu",  "is_correct": false},
      {"id": "d", "text": "pánem", "is_correct": false}
    ]
  }'
),
(
  'e3000001-0000-0000-0000-000000000003',
  'mcq', 'reading', 10,
  '{
    "prompt": "Přečtěte dopis a odpovězte:\n\n''Vážená paní Nováková,\noznamuji Vám, že Vaše žádost o prodloužení pracovní smlouvy byla schválena.\nS pozdravem, Mgr. Petr Svoboda''\n\nCo bylo schváleno?",
    "explanation": "Thư thông báo đơn xin gia hạn hợp đồng lao động đã được chấp thuận.",
    "options": [
      {"id": "a", "text": "Žádost o dovolenou",                          "is_correct": false},
      {"id": "b", "text": "Žádost o prodloužení pracovní smlouvy",       "is_correct": true},
      {"id": "c", "text": "Žádost o zvýšení platu",                      "is_correct": false},
      {"id": "d", "text": "Žádost o přestup na jiné oddělení",           "is_correct": false}
    ]
  }'
),
(
  'e3000001-0000-0000-0000-000000000004',
  'mcq', 'listening', 10,
  '{
    "prompt": "🎧 [Poslech]\nTajemnice: ''Ředitel není k dispozici do 14 hodin. Chcete zanechat zprávu nebo zavolat zpět?''\n\nCo nabízí tajemnice?",
    "explanation": "Thư ký đưa ra hai lựa chọn: để lại tin nhắn (zanechat zprávu) hoặc gọi lại (zavolat zpět).",
    "options": [
      {"id": "a", "text": "Zanechat zprávu nebo počkat",        "is_correct": false},
      {"id": "b", "text": "Zanechat zprávu nebo zavolat zpět", "is_correct": true},
      {"id": "c", "text": "Poslat email nebo přijít osobně",   "is_correct": false},
      {"id": "d", "text": "Zavolat řediteli přímo",            "is_correct": false}
    ]
  }'
),
(
  'e3000001-0000-0000-0000-000000000005',
  'speaking', 'speaking', 10,
  '{
    "prompt": "Voláte do firmy a chcete mluvit s ředitelem. Tajemnice říká, že není k dispozici. Co řeknete?\n\nHãy đóng vai tình huống: gọi điện đến công ty và muốn nói chuyện với giám đốc.",
    "explanation": "Mẫu: Dobrý den, jmenuji se [Jméno]. Chtěl/a bych mluvit s panem ředitelem. Zanechám zprávu — prosím řekněte mu, že jsem volal/a."
  }'
),
(
  'e3000001-0000-0000-0000-000000000006',
  'writing', 'writing', 15,
  '{
    "prompt": "Napište formální dopis (50–80 slov):\n\nJste zaměstnanec firmy ABC. Chcete si vzít 2 týdny dovolené v červenci. Napište žádost svému vedoucímu.\n\nViết thư xin nghỉ phép 2 tuần tháng 7 gửi cho cấp trên.",
    "explanation": "Mẫu:\nVážený pane vedoucí,\ndovolte mi požádat o 2 týdny dovolené od 1. do 14. července. Všechny moje úkoly budou splněny před odchodem.\nDěkuji za pochopení.\nS pozdravem, [Jméno]"
  }'
)
ON CONFLICT DO NOTHING;

-- ── Lesson 4: Giới thiệu về bản thân (Speaking) ─────────────────────────────

INSERT INTO exercises (id, type, skill, xp_reward, content_json) VALUES
(
  'e4000001-0000-0000-0000-000000000001',
  'fill_blank', 'vocabulary', 10,
  '{
    "prompt": "Doplňte správné slovo:\nJmenuji se Pavel. Jsem ______ z Vietnamu.\n(Vietnamec / Česk / Slovák)",
    "correct_answer": "Vietnamec",
    "explanation": "VIETNAMEC = người Việt Nam (nam giới). Jsem Vietnamec = Tôi là người Việt Nam."
  }'
),
(
  'e4000001-0000-0000-0000-000000000002',
  'mcq', 'grammar', 10,
  '{
    "prompt": "Vyberte správný tvar slovesa být:\nJá ______ student.",
    "explanation": "JSEM — với chủ ngữ já (tôi), động từ být chia là jsem. Já jsem student = Tôi là sinh viên.",
    "options": [
      {"id": "a", "text": "jsem", "is_correct": true},
      {"id": "b", "text": "jsi",  "is_correct": false},
      {"id": "c", "text": "je",   "is_correct": false},
      {"id": "d", "text": "jsou", "is_correct": false}
    ]
  }'
),
(
  'e4000001-0000-0000-0000-000000000003',
  'mcq', 'reading', 10,
  '{
    "prompt": "Přečtěte vizitku a odpovězte:\n\n👤 Ing. Jana Procházková\n📧 jana.prochazkova@firma.cz\n📞 +420 777 123 456\n🏢 Manažerka projektu, Firma s.r.o.\n\nJaká je profese Jany Procházkové?",
    "explanation": "Theo danh thiếp, Jana Procházková là Manažerka projektu (Quản lý dự án).",
    "options": [
      {"id": "a", "text": "Účetní",              "is_correct": false},
      {"id": "b", "text": "Manažerka projektu",  "is_correct": true},
      {"id": "c", "text": "Ředitelka",           "is_correct": false},
      {"id": "d", "text": "Sekretářka",          "is_correct": false}
    ]
  }'
),
(
  'e4000001-0000-0000-0000-000000000004',
  'mcq', 'listening', 10,
  '{
    "prompt": "🎧 [Poslech]\nA: ''Dobrý den, jak se jmenujete?''\nB: ''Dobrý den, jmenuji se Nguyen Van An. Jsem z Vietnamu a pracuji jako kuchař.''\n\nCo dělá pan Nguyen?",
    "explanation": "Ông Nguyen tự giới thiệu: pracuji jako kuchař = làm đầu bếp.",
    "options": [
      {"id": "a", "text": "Je učitel", "is_correct": false},
      {"id": "b", "text": "Je kuchař", "is_correct": true},
      {"id": "c", "text": "Je řidič",  "is_correct": false},
      {"id": "d", "text": "Je lékař",  "is_correct": false}
    ]
  }'
),
(
  'e4000001-0000-0000-0000-000000000005',
  'speaking', 'speaking', 10,
  '{
    "prompt": "Představte se česky.\n\nŘekněte:\n• Jméno a příjmení\n• Odkud jste\n• Co děláte (práce / studium)\n• Jak dlouho žijete v ČR\n\nHãy tự giới thiệu bản thân bằng tiếng Séc (tối thiểu 4 câu).",
    "explanation": "Mẫu: Dobrý den, jmenuji se Nguyen Thi Lan. Jsem z Vietnamu. Pracuji jako prodavačka. V České republice žiji 5 let."
  }'
),
(
  'e4000001-0000-0000-0000-000000000006',
  'writing', 'writing', 10,
  '{
    "prompt": "Napište krátký text o sobě (30–50 slov):\n\nVyplňte dotazník — napište o sobě: jméno, původ, zaměstnání, záliby.\n\nViết đoạn giới thiệu bản thân: tên, quê quán, nghề nghiệp, sở thích.",
    "explanation": "Mẫu: Jmenuji se Tran Van Minh. Jsem z Vietnamu, ale žiji v Praze. Pracuji v restauraci. Ve volném čase rád hraji fotbal."
  }'
)
ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN B — LESSON BLOCKS (24 rows: 6 blocks × 4 lessons)
-- Lesson IDs đã xác nhận trong DB:
--   00000000-0000-0000-0011-000000000001 = Reading
--   00000000-0000-0000-0022-000000000001 = Listening
--   00000000-0000-0000-0033-000000000001 = Writing
--   00000000-0000-0000-0044-000000000001 = Speaking
-- ═════════════════════════════════════════════════════════════════════════════

-- Lesson 1 — Đọc biển hiệu và thông báo (Reading)
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
('b1000001-0000-0000-0000-000000000001','00000000-0000-0000-0011-000000000001','vocab',     'e1000001-0000-0000-0000-000000000001',1),
('b1000001-0000-0000-0000-000000000002','00000000-0000-0000-0011-000000000001','grammar',   'e1000001-0000-0000-0000-000000000002',2),
('b1000001-0000-0000-0000-000000000003','00000000-0000-0000-0011-000000000001','reading',   'e1000001-0000-0000-0000-000000000003',3),
('b1000001-0000-0000-0000-000000000004','00000000-0000-0000-0011-000000000001','listening', 'e1000001-0000-0000-0000-000000000004',4),
('b1000001-0000-0000-0000-000000000005','00000000-0000-0000-0011-000000000001','speaking',  'e1000001-0000-0000-0000-000000000005',5),
('b1000001-0000-0000-0000-000000000006','00000000-0000-0000-0011-000000000001','writing',   'e1000001-0000-0000-0000-000000000006',6)
ON CONFLICT DO NOTHING;

-- Lesson 2 — Nghe chỉ đường (Listening)
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
('b2000001-0000-0000-0000-000000000001','00000000-0000-0000-0022-000000000001','vocab',     'e2000001-0000-0000-0000-000000000001',1),
('b2000001-0000-0000-0000-000000000002','00000000-0000-0000-0022-000000000001','grammar',   'e2000001-0000-0000-0000-000000000002',2),
('b2000001-0000-0000-0000-000000000003','00000000-0000-0000-0022-000000000001','reading',   'e2000001-0000-0000-0000-000000000003',3),
('b2000001-0000-0000-0000-000000000004','00000000-0000-0000-0022-000000000001','listening', 'e2000001-0000-0000-0000-000000000004',4),
('b2000001-0000-0000-0000-000000000005','00000000-0000-0000-0022-000000000001','speaking',  'e2000001-0000-0000-0000-000000000005',5),
('b2000001-0000-0000-0000-000000000006','00000000-0000-0000-0022-000000000001','writing',   'e2000001-0000-0000-0000-000000000006',6)
ON CONFLICT DO NOTHING;

-- Lesson 3 — Viết email xin việc (Writing)
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
('b3000001-0000-0000-0000-000000000001','00000000-0000-0000-0033-000000000001','vocab',     'e3000001-0000-0000-0000-000000000001',1),
('b3000001-0000-0000-0000-000000000002','00000000-0000-0000-0033-000000000001','grammar',   'e3000001-0000-0000-0000-000000000002',2),
('b3000001-0000-0000-0000-000000000003','00000000-0000-0000-0033-000000000001','reading',   'e3000001-0000-0000-0000-000000000003',3),
('b3000001-0000-0000-0000-000000000004','00000000-0000-0000-0033-000000000001','listening', 'e3000001-0000-0000-0000-000000000004',4),
('b3000001-0000-0000-0000-000000000005','00000000-0000-0000-0033-000000000001','speaking',  'e3000001-0000-0000-0000-000000000005',5),
('b3000001-0000-0000-0000-000000000006','00000000-0000-0000-0033-000000000001','writing',   'e3000001-0000-0000-0000-000000000006',6)
ON CONFLICT DO NOTHING;

-- Lesson 4 — Giới thiệu về bản thân (Speaking)
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
('b4000001-0000-0000-0000-000000000001','00000000-0000-0000-0044-000000000001','vocab',     'e4000001-0000-0000-0000-000000000001',1),
('b4000001-0000-0000-0000-000000000002','00000000-0000-0000-0044-000000000001','grammar',   'e4000001-0000-0000-0000-000000000002',2),
('b4000001-0000-0000-0000-000000000003','00000000-0000-0000-0044-000000000001','reading',   'e4000001-0000-0000-0000-000000000003',3),
('b4000001-0000-0000-0000-000000000004','00000000-0000-0000-0044-000000000001','listening', 'e4000001-0000-0000-0000-000000000004',4),
('b4000001-0000-0000-0000-000000000005','00000000-0000-0000-0044-000000000001','speaking',  'e4000001-0000-0000-0000-000000000005',5),
('b4000001-0000-0000-0000-000000000006','00000000-0000-0000-0044-000000000001','writing',   'e4000001-0000-0000-0000-000000000006',6)
ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN C — AI SPEAKING ATTEMPT STUB (status=ready, user_id=NULL — gắn sau)
-- ID cố định để seed_user.sql có thể UPDATE user_id
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO ai_speaking_attempts (
  id, user_id, exercise_id, audio_key, status,
  overall_score, metrics, transcript, issues, strengths, improvements, corrected_answer
) VALUES (
  'a15ea001-0000-0000-0000-000000000001',
  NULL,
  'e1000001-0000-0000-0000-000000000005',
  'speaking/demo/sample_audio.webm',
  'ready',
  76,
  '{"pronunciation": 7, "fluency": 8, "vocabulary": 6}',
  'Vstávám v sedm hodin. Jdu do práce autobus. Odpoledne vracím domů a vařím večeři.',
  '[
    {"word": "autobus", "suggestion": "autobusem (instrumentál — způsob přepravy vyžaduje cách 7)"},
    {"word": "vracím", "suggestion": "vracím se (reflexivní sloveso — chưa có se)"}
  ]',
  ARRAY[
    'Plynulá řeč bez dlouhých pauz',
    'Dobrá výslovnost samohlásek',
    'Správné použití přítomného času'
  ],
  ARRAY[
    'Procvičte instrumentál pro způsob přepravy: autobusem, tramvají, autem',
    'Nezapomeňte reflexivní zájmena: vracet SE, těšit SE'
  ],
  'Vstávám v sedm hodin. Jdu do práce autobusem. Odpoledne se vracím domů a vařím večeři.'
) ON CONFLICT DO NOTHING;


-- ═════════════════════════════════════════════════════════════════════════════
-- PHẦN D — AI WRITING ATTEMPT STUB (status=ready, user_id=NULL — gắn sau)
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO ai_writing_attempts (
  id, user_id, exercise_id, prompt_text, answer_text, rubric_type, status,
  overall_score, metrics, grammar_notes, vocabulary_notes, corrected_essay
) VALUES (
  'a17e1001-0000-0000-0000-000000000001',
  NULL,
  'e1000001-0000-0000-0000-000000000006',
  'Napište krátký email s poděkováním sousedce paní Horákové, která vám pomohla s nákupem.',
  'Vážená paní Horáková, chci vám poděkovat za pomoc nákupem. Bylo to velmi hezké. Jsem vám vděčný. S pozdravem, Minh',
  'letter',
  'ready',
  82,
  '{"grammar": 8, "vocabulary": 8, "coherence": 8, "task_achievement": 9}',
  '[
    {"original": "za pomoc nákupem", "corrected": "za pomoc s nákupem", "explanation": "Sloveso pomoc vyžaduje předložku s + instrumentál: pomoc S nákupem."},
    {"original": "hezké", "corrected": "milé nebo laskavé", "explanation": "Hezký (hezké) se používá spíše pro věci/osoby. Pro čin/gesto je vhodnější milé nebo laskavé."}
  ]',
  '[
    {"original": "vděčný", "suggestion": "velmi vám vděčný / nesmírně vděčný — zesílení vyjadřuje upřímnější poděkování"}
  ]',
  'Vážená paní Horáková,\nchci vám poděkovat za vaši pomoc s nákupem. Bylo to velmi milé a laskavé z vaší strany. Jsem vám velmi vděčný/á.\nS pozdravem,\nMinh'
) ON CONFLICT DO NOTHING;
