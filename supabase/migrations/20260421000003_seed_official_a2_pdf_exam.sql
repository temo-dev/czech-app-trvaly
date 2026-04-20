-- Official 2025 NPI A2 model exam (closest in-app mapping)

UPDATE public.exams
SET is_active = false
WHERE is_active = true;

INSERT INTO public.exams (id, title, duration_minutes, is_active)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'Trvalý pobyt — Modelový test A2 (NPI 2025)',
  120,
  true
);

INSERT INTO public.exam_sections (
  id,
  exam_id,
  skill,
  label,
  question_count,
  section_duration_minutes,
  order_index
) VALUES
  ('bbbbbbbb-2222-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'reading',  'Đọc hiểu (Čtení)',     25, 40, 1),
  ('bbbbbbbb-2222-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'writing',  'Viết (Psaní)',          2, 25, 2),
  ('bbbbbbbb-2222-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'listening','Nghe hiểu (Poslech)',  25, 40, 3),
  ('bbbbbbbb-2222-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'speaking', 'Nói (Mluvení)',         4, 15, 4);

-- ── READING ────────────────────────────────────────────────────────────────

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, image_url, explanation, points, order_index
) VALUES
  ('20000001-0000-0000-0000-000000000001', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$Nhìn hình 1. Thông tin nào phù hợp nhất với hình này?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/official-a2-2025/reading-task1-q1.png', $$Đây là quầy nhận bưu kiện nên đáp án đúng là thông báo nhận hàng tại quầy 3.$$ , 1, 1),
  ('20000001-0000-0000-0000-000000000002', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$Nhìn hình 2. Thông tin nào phù hợp nhất với hình này?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/official-a2-2025/reading-task1-q2.png', $$Tòa nhà là khoa phẫu thuật nên đáp án đúng là thông báo tiếp nhận ở khoa chirurgii.$$ , 1, 2),
  ('20000001-0000-0000-0000-000000000003', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$Nhìn hình 3. Thông tin nào phù hợp nhất với hình này?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/official-a2-2025/reading-task1-q3.png', $$Đây là tiệm cắt tóc, vì vậy thông báo hẹn cắt lúc 16:00 là phù hợp nhất.$$ , 1, 3),
  ('20000001-0000-0000-0000-000000000004', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$Nhìn hình 4. Thông tin nào phù hợp nhất với hình này?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/official-a2-2025/reading-task1-q4.png', $$Hình thể hiện xe đã được sửa xong và bàn giao cho khách.$$ , 1, 4),
  ('20000001-0000-0000-0000-000000000005', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$Nhìn hình 5. Thông tin nào phù hợp nhất với hình này?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/official-a2-2025/reading-task1-q5.png', $$Hình cho thấy thợ sửa máy giặt, vì vậy thông báo máy giặt đã sửa xong là chính xác.$$ , 1, 5);

INSERT INTO public.question_options (question_id, text, is_correct, order_index)
SELECT q.question_id::uuid, o.text, o.order_index = q.correct_order, o.order_index
FROM (
  VALUES
    ('20000001-0000-0000-0000-000000000001', 4),
    ('20000001-0000-0000-0000-000000000002', 2),
    ('20000001-0000-0000-0000-000000000003', 8),
    ('20000001-0000-0000-0000-000000000004', 6),
    ('20000001-0000-0000-0000-000000000005', 3)
) AS q(question_id, correct_order)
CROSS JOIN (
  VALUES
    (1, 'A) Dovolená 12.–20. 8. Cykloservis.'),
    (2, 'B) Příjem na chirurgii od 7:00. Na viděnou.'),
    (3, 'C) Vaše pračka už je opravená. Zavolejte.'),
    (4, 'D) Balík si můžete vyzvednout u přepážky 3.'),
    (5, 'E) Děkujeme za objednávku. Kosmetika Alan.'),
    (6, 'F) Vaše auto je připravené. Autoservis Vexa.'),
    (7, 'G) Máte zájem o ten sporák? Kuchyně Lima.'),
    (8, 'H) Můžu vás ostříhat dnes v 16:00. J. Novotná.'),
    (9, 'I) Celodenní parkování zdarma. Město Brno.')
) AS o(order_index, text);

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, passage_text, explanation, points, order_index
) VALUES
  ('20000001-0000-0000-0000-000000000006', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$6. Kdy skončila stavba sportoviště?$$, $$Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta$$, $$Trong thông báo có ghi rõ công trình kéo dài đến 30. 4. 2025.$$ , 1, 6),
  ('20000001-0000-0000-0000-000000000007', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$7. Kdy můžete jít na fotbalové hřiště v měsíci říjnu?$$, $$Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta$$, $$Trong tháng 10 khu này mở từ 9:00 đến 18:00.$$ , 1, 7),
  ('20000001-0000-0000-0000-000000000008', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$8. Ve kterém měsíci bude celý areál zavřený?$$, $$Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta$$, $$Từ tháng 11 đến tháng 3 khu thể thao đóng cửa, nên prosinec là một đáp án đúng.$$ , 1, 8),
  ('20000001-0000-0000-0000-000000000009', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$9. Pro koho je sportoviště zadarmo?$$, $$Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta$$, $$Thông báo viết rõ chỉ có školy là không phải trả phí.$$ , 1, 9),
  ('20000001-0000-0000-0000-000000000010', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$10. Co chce starosta ještě vybudovat?$$, $$Vážení spoluobčané,
všechny Vás zveme na slavnostní otevření nového sportoviště, které se koná dne 25. 6. a kterého se zúčastní také jeho architekt, pan inženýr Kučera. Zároveň oznamujeme, že od 1. 6. je sportoviště v provozu. Stavba trvala od 10. 5. 2023 do 30. 4. 2025.

Sportoviště zahrnuje hřiště na fotbal, volejbalové kurty, hřiště na basketbal a plavecký bazén. V červenci ještě otevřeme tenisové kurty. O sportoviště se budou starat pánové I. Písecký a M. Hulák.

V areálu bude otevřeno každý den od 8:00 do 20:00 hodin od května do září a od 9:00 do 18:00 hodin v dubnu a v říjnu. Od listopadu do března bude areál uzavřený. Pozor, bazén bude otevřen pouze v létě.

Všichni uživatelé si musí rezervovat dobu návštěvy přes on-line systém a také zaplatit poplatek. Individuální sportovci z naší obce platí 150 Kč/h, občané z okolních obcí 200 Kč/h, za klubové sportovce platí jejich kluby. Poplatky neplatí pouze školy.

Otevřením sportoviště naše práce nekončí. Máme ještě v plánu vybudovat saunu a fitness centrum.

Petr Smažík, starosta$$, $$Starosta nói còn muốn xây thêm sauna và fitness centrum.$$ , 1, 10);

INSERT INTO public.question_options (question_id, text, is_correct, order_index) VALUES
  ('20000001-0000-0000-0000-000000000006', 'A) 1. června.', false, 1),
  ('20000001-0000-0000-0000-000000000006', 'B) 30. dubna.', true, 2),
  ('20000001-0000-0000-0000-000000000006', 'C) 10. května.', false, 3),
  ('20000001-0000-0000-0000-000000000006', 'D) 25. června.', false, 4),
  ('20000001-0000-0000-0000-000000000007', 'A) V 8:00.', false, 1),
  ('20000001-0000-0000-0000-000000000007', 'B) V 9:00.', true, 2),
  ('20000001-0000-0000-0000-000000000007', 'C) V 19:00.', false, 3),
  ('20000001-0000-0000-0000-000000000007', 'D) V 20:00.', false, 4),
  ('20000001-0000-0000-0000-000000000008', 'A) V září.', false, 1),
  ('20000001-0000-0000-0000-000000000008', 'B) V dubnu.', false, 2),
  ('20000001-0000-0000-0000-000000000008', 'C) V červnu.', false, 3),
  ('20000001-0000-0000-0000-000000000008', 'D) V prosinci.', true, 4),
  ('20000001-0000-0000-0000-000000000009', 'A) Pro školy.', true, 1),
  ('20000001-0000-0000-0000-000000000009', 'B) Pro kluby z obce.', false, 2),
  ('20000001-0000-0000-0000-000000000009', 'C) Pro lidi z okolních obcí.', false, 3),
  ('20000001-0000-0000-0000-000000000009', 'D) Pro individuální sportovce.', false, 4),
  ('20000001-0000-0000-0000-000000000010', 'A) Kurty.', false, 1),
  ('20000001-0000-0000-0000-000000000010', 'B) Saunu.', true, 2),
  ('20000001-0000-0000-0000-000000000010', 'C) Další hřiště.', false, 3),
  ('20000001-0000-0000-0000-000000000010', 'D) Rezervační systém.', false, 4);

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, intro_text, explanation, points, order_index
) VALUES
  ('20000001-0000-0000-0000-000000000011', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$11. Nabídka: Kurz pro pokročilé informatiky, kteří hledají práci. Kdo je vhodný?$$, $$A) Mariya: dvě malé děti, mluví dobře česky, potřebuje poradit s hledáním práce.
B) Iva: skončila střední školu v ČR, baví ji móda a chce mít živnost.
C) Lada: pracovala jako vedoucí IT oddělení a chce doplnit vzdělání.
D) Ria: přijela s dcerou, rády pečou a chce vařit v restauraci.
E) Anton: inženýr, hledá práci v německé firmě a potřebuje němčinu.
F) Bao: byla dlouho v domácnosti, je jí 56 let a potřebuje základy práce s počítačem.$$, $$Kurz pro pokročilé informatiky odpovídá profilu Lady z IT.$$ , 1, 11),
  ('20000001-0000-0000-0000-000000000012', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$12. Nabídka: Jazyková škola Sprich nabízí kurzy němčiny pro mírně a středně pokročilé. Kdo je vhodný?$$, $$A) Mariya: dvě malé děti, mluví dobře česky, potřebuje poradit s hledáním práce.
B) Iva: skončila střední školu v ČR, baví ji móda a chce mít živnost.
C) Lada: pracovala jako vedoucí IT oddělení a chce doplnit vzdělání.
D) Ria: přijela s dcerou, rády pečou a chce vařit v restauraci.
E) Anton: inženýr, hledá práci v německé firmě a potřebuje němčinu.
F) Bao: byla dlouho v domácnosti, je jí 56 let a potřebuje základy práce s počítačem.$$, $$Anton cần cải thiện tiếng Đức nên đây là người phù hợp nhất.$$ , 1, 12),
  ('20000001-0000-0000-0000-000000000013', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$13. Nabídka: Společenské centrum poradí s trhem práce a nabízí dětský klub pro děti 3–15 let. Kdo je vhodný?$$, $$A) Mariya: dvě malé děti, mluví dobře česky, potřebuje poradit s hledáním práce.
B) Iva: skončila střední školu v ČR, baví ji móda a chce mít živnost.
C) Lada: pracovala jako vedoucí IT oddělení a chce doplnit vzdělání.
D) Ria: přijela s dcerou, rády pečou a chce vařit v restauraci.
E) Anton: inženýr, hledá práci v německé firmě a potřebuje němčinu.
F) Bao: byla dlouho v domácnosti, je jí 56 let a potřebuje základy práce s počítačem.$$, $$Mariya vừa cần tìm việc vừa không có người trông con, nên trung tâm có dětský klub rất phù hợp.$$ , 1, 13),
  ('20000001-0000-0000-0000-000000000014', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$14. Nabídka: Kurz vaření se šéfkuchařem, mohou přijít i starší děti. Kdo je vhodný?$$, $$A) Mariya: dvě malé děti, mluví dobře česky, potřebuje poradit s hledáním práce.
B) Iva: skončila střední školu v ČR, baví ji móda a chce mít živnost.
C) Lada: pracovala jako vedoucí IT oddělení a chce doplnit vzdělání.
D) Ria: přijela s dcerou, rády pečou a chce vařit v restauraci.
E) Anton: inženýr, hledá práci v německé firmě a potřebuje němčinu.
F) Bao: byla dlouho v domácnosti, je jí 56 let a potřebuje základy práce s počítačem.$$, $$Ria muốn làm bếp và có con gái lớn đi cùng nên đáp án là Ria.$$ , 1, 14);

INSERT INTO public.question_options (question_id, text, is_correct, order_index)
SELECT q.question_id::uuid, o.text, o.order_index = q.correct_order, o.order_index
FROM (
  VALUES
    ('20000001-0000-0000-0000-000000000011', 3),
    ('20000001-0000-0000-0000-000000000012', 5),
    ('20000001-0000-0000-0000-000000000013', 1),
    ('20000001-0000-0000-0000-000000000014', 4)
) AS q(question_id, correct_order)
CROSS JOIN (
  VALUES
    (1, 'A) Mariya'),
    (2, 'B) Iva'),
    (3, 'C) Lada'),
    (4, 'D) Ria'),
    (5, 'E) Anton'),
    (6, 'F) Bao')
) AS o(order_index, text);

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, explanation, points, order_index
) VALUES
  ('20000001-0000-0000-0000-000000000015', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$15. Cestovní agentura A–Z: Nabízíme prodej a rezervaci jízdenek pro _________ a mezinárodní autobusovou a vlakovou dopravu. $$, $$Slovo vnitrostátní znamená “nội địa”, đối lập với mezinárodní.$$ , 1, 15),
  ('20000001-0000-0000-0000-000000000016', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$16. Cestovní pojištění: U nás vám _________ pomůžeme. $$, $$Cụm đúng là rádi pomůžeme = chúng tôi rất sẵn lòng giúp.$$ , 1, 16),
  ('20000001-0000-0000-0000-000000000017', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$17. Restaurace Za Mlýnem: Do nově otevřené restaurace _________ kuchaře/kuchařku na plný úvazek. $$, $$Cụm tuyển dụng chuẩn là přijmeme kuchaře/kuchařku.$$ , 1, 17),
  ('20000001-0000-0000-0000-000000000018', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$18. Vždy čerstvé! Nakupujte v našem novém _________ u stanice metra Opatov. Každý den čerstvý chléb, rohlíky a zákusky. $$, $$Các mặt hàng gợi ý rõ đây là pekařství, tức tiệm bánh.$$ , 1, 18),
  ('20000001-0000-0000-0000-000000000019', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$19. Max banka: Chcete si otevřít nový běžný _________, kam budete posílat svůj plat? $$, $$Běžný účet là tài khoản thanh toán hàng ngày tại ngân hàng.$$ , 1, 19),
  ('20000001-0000-0000-0000-000000000020', 'bbbbbbbb-2222-0000-0000-000000000001', 'mcq', 'reading', $$20. Ranní zprávy: Za silvestrovskou noc vyjížděli hasiči k několika požárům. V panelovém domě u náměstí _________ byt ve druhém patře. $$, $$V ngữ cảnh cháy nhà, động từ đúng là hořel = đã bốc cháy.$$ , 1, 20);

INSERT INTO public.question_options (question_id, text, is_correct, order_index) VALUES
  ('20000001-0000-0000-0000-000000000015', 'A) vnitrostátní', true, 1),
  ('20000001-0000-0000-0000-000000000015', 'B) přestupní', false, 2),
  ('20000001-0000-0000-0000-000000000015', 'C) cestovní', false, 3),
  ('20000001-0000-0000-0000-000000000015', 'D) hlavní', false, 4),
  ('20000001-0000-0000-0000-000000000016', 'A) dlouho', false, 1),
  ('20000001-0000-0000-0000-000000000016', 'B) dávno', false, 2),
  ('20000001-0000-0000-0000-000000000016', 'C) příště', false, 3),
  ('20000001-0000-0000-0000-000000000016', 'D) rádi', true, 4),
  ('20000001-0000-0000-0000-000000000017', 'A) přijmeme', true, 1),
  ('20000001-0000-0000-0000-000000000017', 'B) nabízíme', false, 2),
  ('20000001-0000-0000-0000-000000000017', 'C) čekáme', false, 3),
  ('20000001-0000-0000-0000-000000000017', 'D) vaříme', false, 4),
  ('20000001-0000-0000-0000-000000000018', 'A) květinářství', false, 1),
  ('20000001-0000-0000-0000-000000000018', 'B) papírnictví', false, 2),
  ('20000001-0000-0000-0000-000000000018', 'C) pekařství', true, 3),
  ('20000001-0000-0000-0000-000000000018', 'D) řeznictví', false, 4),
  ('20000001-0000-0000-0000-000000000019', 'A) pojištění', false, 1),
  ('20000001-0000-0000-0000-000000000019', 'B) nájem', false, 2),
  ('20000001-0000-0000-0000-000000000019', 'C) servis', false, 3),
  ('20000001-0000-0000-0000-000000000019', 'D) účet', true, 4),
  ('20000001-0000-0000-0000-000000000020', 'A) svítil', false, 1),
  ('20000001-0000-0000-0000-000000000020', 'B) voněl', false, 2),
  ('20000001-0000-0000-0000-000000000020', 'C) hořel', true, 3),
  ('20000001-0000-0000-0000-000000000020', 'D) ležel', false, 4);

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, intro_text, correct_answer, accepted_answers, explanation, points, order_index
) VALUES
  ('20000001-0000-0000-0000-000000000021', 'bbbbbbbb-2222-0000-0000-000000000001', 'fill_blank', 'reading', $$21. Podle receptu můžeme připravit _________ salát. $$, $$Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.$$, 'bramborový', ARRAY['bramborovy'], $$Tên món ngay đầu bài là bramborový salát.$$ , 1, 21),
  ('20000001-0000-0000-0000-000000000022', 'bbbbbbbb-2222-0000-0000-000000000001', 'fill_blank', 'reading', $$22. Na salát potřebujeme jednu _________ cibuli. $$, $$Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.$$, 'velkou', ARRAY['velká'], $$Trong danh sách nguyên liệu có “1 velkou cibuli”.$$ , 1, 22),
  ('20000001-0000-0000-0000-000000000023', 'bbbbbbbb-2222-0000-0000-000000000001', 'fill_blank', 'reading', $$23. Na salát není vhodné použít olivový _________. $$, $$Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.$$, 'olej', ARRAY['oleje'], $$Câu nguyên liệu ghi “1 lžíci oleje, ne olivového”.$$ , 1, 23),
  ('20000001-0000-0000-0000-000000000024', 'bbbbbbbb-2222-0000-0000-000000000001', 'fill_blank', 'reading', $$24. Brambory uvaříme 1 _________ před přípravou salátu. $$, $$Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.$$, 'den', ARRAY['jeden den'], $$Bước 1 nói rõ brambory uvaříme den předem.$$ , 1, 24),
  ('20000001-0000-0000-0000-000000000025', 'bbbbbbbb-2222-0000-0000-000000000001', 'fill_blank', 'reading', $$25. K salátu se nejlépe hodí řízek nebo _________. $$, $$Bramborový salát z Pohořelic

Na tento bramborový salát budete potřebovat:
1 kg vařených brambor, 4 vajíčka, 1 velkou cibuli, 1 lžíci hořčice, 1 lžíci oleje, ne olivového, 4 kyselé okurky, 1 větší mrkev, 1 sklenici majonézy.

Příprava:
1. Brambory uvaříme den předem.
2. Cibuli nakrájíme nadrobno.
3. Vejce uvaříme natvrdo a přidáme k cibuli a bramborům.
4. Mrkev uvaříme a spolu s okurkami nakrájíme a přidáme do salátu.
5. Nakonec přidáme olej, pepř, sůl, hořčici a majonézu.
6. Vše dobře promícháme a servírujeme, nejlépe s řízkem nebo rybou.$$, 'rybou', ARRAY['ryba'], $$Câu cuối ghi “nejlépe s řízkem nebo rybou”.$$ , 1, 25);

-- ── WRITING ────────────────────────────────────────────────────────────────

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index
) VALUES
  ('30000001-0000-0000-0000-000000000001', 'bbbbbbbb-2222-0000-0000-000000000002', 'writing', 'writing', $$ÚLOHA 1 – Formulář

Odpovězte na tři otázky pro e-shop Maxi-drogerie.cz.
1. Jak jste získal/a informace o našem e-shopu?
2. Proč v našem e-shopu nakupujete?
3. Které služby nebo informace vám v našem e-shopu chybí?

Yêu cầu:
- Viết bằng tiếng Séc.
- Trả lời cả 3 câu hỏi.
- Mỗi câu tối thiểu 10 từ.$$,
$$Rubric chính thức:
- Trả lời đủ 3 câu hỏi.
- Mỗi câu là một câu hoàn chỉnh, tối thiểu 10 từ.
- Nội dung rõ ràng, phù hợp ngữ cảnh khảo sát e-shop.
- Ngữ pháp và từ vựng ở mức A2, dễ hiểu.$$,
$$Ví dụ tham khảo: O vašem e-shopu mi řekla kamarádka... / Máte dobré ceny... / Chybí mi větší výběr bio produktů...$$,
8,
1),
  ('30000001-0000-0000-0000-000000000002', 'bbbbbbbb-2222-0000-0000-000000000002', 'writing', 'writing', $$ÚLOHA 2 – E-mail

Napište kamarádce Petře pozdrav z dovolené.
Bạn phải viết:
- 1 câu chào / mở thư.
- 1 câu cho mỗi ý sau:
  1. Kde jste?
  2. Jak dlouho tam jste?
  3. Kde bydlíte?
  4. Co děláte dopoledne?
  5. Co děláte odpoledne?

Yêu cầu:
- Viết bằng tiếng Séc.
- Tối thiểu 35 từ.$$,
$$Rubric chính thức:
- Có lời chào và phản hồi đủ cả 5 ý trong đề.
- Tối thiểu 35 từ, bố cục như e-mail ngắn.
- Diễn đạt rõ ràng, phù hợp bối cảnh đi nghỉ.
- Ngữ pháp, chính tả và mạch ý ở mức A2.$$,
$$Ví dụ tham khảo: Ahoj Petro, posílám Ti pozdrav z dovolené. Jsem v Itálii u moře...$$,
12,
2);

-- ── LISTENING ──────────────────────────────────────────────────────────────

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, audio_url, explanation, points, order_index
) VALUES
  ('40000001-0000-0000-0000-000000000001', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$1. Jak se ten muž dostane teď na nádraží?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task1-q1.wav', $$Người phụ nữ nói rõ trolejbus číslo čtyři đi tới nádraží.$$ , 1, 1),
  ('40000001-0000-0000-0000-000000000002', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$2. Kam půjde Ludvík tuhle neděli?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task1-q2.wav', $$Ludvík říká, že v neděli jedou do muzea.$$ , 1, 2),
  ('40000001-0000-0000-0000-000000000003', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$3. Co teď musí koupit Irena?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task1-q3.wav', $$Irena říká, že musí koupit hlavně auto.$$ , 1, 3),
  ('40000001-0000-0000-0000-000000000004', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$4. Kde je teď Martin?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task1-q4.wav', $$Martin říká “ještě jsem v práci” a musí něco dodělat v kanceláři.$$ , 1, 4),
  ('40000001-0000-0000-0000-000000000005', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$5. Kam jde muž?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task1-q5.wav', $$Muž jde na rehabilitaci, ne k doktorovi.$$ , 1, 5),
  ('40000001-0000-0000-0000-000000000006', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$6. Jaká je sleva na vepřové maso?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task2-q6.wav', $$Trong thông báo siêu thị có ghi vepřové maso se slevou třináct procent.$$ , 1, 6),
  ('40000001-0000-0000-0000-000000000007', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$7. Který kurz teď můžete navštěvovat v úterý?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task2-q7.wav', $$V úterý se koná kurz pro mírně pokročilé.$$ , 1, 7),
  ('40000001-0000-0000-0000-000000000008', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$8. Do kterého města nejede autobus s odjezdem v 9 hodin?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task2-q8.wav', $$Autobus už nebude zastavovat ve městě Louny.$$ , 1, 8),
  ('40000001-0000-0000-0000-000000000009', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$9. Jaký základní plat nabízí restaurace číšníkovi?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task2-q9.wav', $$Pro číšníky restaurace nabízí třicet tisíc korun měsíčně.$$ , 1, 9),
  ('40000001-0000-0000-0000-000000000010', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$10. Kdy bude teplota na horách až -10 °C?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task2-q10.wav', $$Dự báo nói “v sobotu v noci” trên núi có thể xuống đến minus deset.$$ , 1, 10),
  ('40000001-0000-0000-0000-000000000011', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$11. Jaký koníček má teď Leila?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task3-q11.wav', $$Leila říká, že teď fotografuje přírodu, parky a květiny.$$ , 1, 11),
  ('40000001-0000-0000-0000-000000000012', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$12. Jaký koníček má teď Džamila?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task3-q12.wav', $$Džamila stále kreslí, nejraději obrazy přírody.$$ , 1, 12),
  ('40000001-0000-0000-0000-000000000013', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$13. Jaký koníček má teď Ivona?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task3-q13.wav', $$Ivona říká, že dnes hlavně čte knihy.$$ , 1, 13),
  ('40000001-0000-0000-0000-000000000014', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$14. Jaký koníček má teď Hindi?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task3-q14.wav', $$Hindi dnes nejvíc baví plavání.$$ , 1, 14),
  ('40000001-0000-0000-0000-000000000015', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$15. Jaký koníček má teď Naďa?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task3-q15.wav', $$Naďa říká, že ji ze všeho nejvíc baví vaření.$$ , 1, 15),
  ('40000001-0000-0000-0000-000000000016', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$16. Co chce ta žena koupit?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task4-q16.wav', $$Žena hledá bavlněné bílé tričko.$$ , 1, 16),
  ('40000001-0000-0000-0000-000000000017', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$17. Co chce ten muž koupit?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task4-q17.wav', $$Muž chce teplé rukavice.$$ , 1, 17),
  ('40000001-0000-0000-0000-000000000018', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$18. Co potřebuje ten muž na svatbu?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task4-q18.wav', $$Potřebuje kravatu na svatbu.$$ , 1, 18),
  ('40000001-0000-0000-0000-000000000019', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$19. Jaké oblečení potřebuje ta žena?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task4-q19.wav', $$Žena chce růžové šaty na svatbu své sestry.$$ , 1, 19),
  ('40000001-0000-0000-0000-000000000020', 'bbbbbbbb-2222-0000-0000-000000000003', 'mcq', 'listening', $$20. Jaké oblečení chce ta žena?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task4-q20.wav', $$Žena chce zimní kabát velikosti L nebo XL.$$ , 1, 20),
  ('40000001-0000-0000-0000-000000000021', 'bbbbbbbb-2222-0000-0000-000000000003', 'fill_blank', 'listening', $$21. KDO volá?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task5-message.wav', $$Volající se představí slovy “tady Eva”.$$ , 1, 21),
  ('40000001-0000-0000-0000-000000000022', 'bbbbbbbb-2222-0000-0000-000000000003', 'fill_blank', 'listening', $$22. KTERÝ DEN bude balet?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task5-message.wav', $$Vzkaz říká “ve čtvrtek dvacátého osmého dubna”.$$ , 1, 22),
  ('40000001-0000-0000-0000-000000000023', 'bbbbbbbb-2222-0000-0000-000000000003', 'fill_blank', 'listening', $$23. KOLIKÁTÉHO bude balet?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task5-message.wav', $$Ngày biểu diễn là 28. dubna.$$ , 1, 23),
  ('40000001-0000-0000-0000-000000000024', 'bbbbbbbb-2222-0000-0000-000000000003', 'fill_blank', 'listening', $$24. JAK se jmenuje restaurace?$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task5-message.wav', $$Eva navrhuje restauraci Klášterní.$$ , 1, 24),
  ('40000001-0000-0000-0000-000000000025', 'bbbbbbbb-2222-0000-0000-000000000003', 'fill_blank', 'listening', $$25. TELEFON Evy? (doplňte část po předtištěném “773”)$$, 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/audio/official-a2-2025/listening-task5-message.wav', $$Số điện thoại hoàn chỉnh là 773 932 504, đề chỉ yêu cầu điền phần cuối.$$ , 1, 25);

INSERT INTO public.question_options (question_id, text, is_correct, order_index) VALUES
  ('40000001-0000-0000-0000-000000000001', 'A) Trolejbusem.', true, 1),
  ('40000001-0000-0000-0000-000000000001', 'B) Autobusem.', false, 2),
  ('40000001-0000-0000-0000-000000000001', 'C) Taxíkem.', false, 3),
  ('40000001-0000-0000-0000-000000000001', 'D) Pěšky.', false, 4),
  ('40000001-0000-0000-0000-000000000002', 'A) Do muzea.', true, 1),
  ('40000001-0000-0000-0000-000000000002', 'B) Na stadion.', false, 2),
  ('40000001-0000-0000-0000-000000000002', 'C) Na zahradu.', false, 3),
  ('40000001-0000-0000-0000-000000000002', 'D) Do restaurace.', false, 4),
  ('40000001-0000-0000-0000-000000000003', 'A) Dům.', false, 1),
  ('40000001-0000-0000-0000-000000000003', 'B) Auto.', true, 2),
  ('40000001-0000-0000-0000-000000000003', 'C) Bazén.', false, 3),
  ('40000001-0000-0000-0000-000000000003', 'D) Zahradu.', false, 4),
  ('40000001-0000-0000-0000-000000000004', 'A) Na poště.', false, 1),
  ('40000001-0000-0000-0000-000000000004', 'B) V akvaparku.', false, 2),
  ('40000001-0000-0000-0000-000000000004', 'C) V kanceláři.', true, 3),
  ('40000001-0000-0000-0000-000000000004', 'D) V autoservisu.', false, 4),
  ('40000001-0000-0000-0000-000000000005', 'A) Na rentgen.', false, 1),
  ('40000001-0000-0000-0000-000000000005', 'B) Do čekárny.', false, 2),
  ('40000001-0000-0000-0000-000000000005', 'C) Do laboratoře.', false, 3),
  ('40000001-0000-0000-0000-000000000005', 'D) Na rehabilitaci.', true, 4),
  ('40000001-0000-0000-0000-000000000006', 'A) 10 %.', false, 1),
  ('40000001-0000-0000-0000-000000000006', 'B) 12 %.', false, 2),
  ('40000001-0000-0000-0000-000000000006', 'C) 13 %.', true, 3),
  ('40000001-0000-0000-0000-000000000006', 'D) 15 %.', false, 4),
  ('40000001-0000-0000-0000-000000000007', 'A) Pro středně pokročilé.', false, 1),
  ('40000001-0000-0000-0000-000000000007', 'B) Pro mírně pokročilé.', true, 2),
  ('40000001-0000-0000-0000-000000000007', 'C) Pro začátečníky.', false, 3),
  ('40000001-0000-0000-0000-000000000007', 'D) Pro pokročilé.', false, 4),
  ('40000001-0000-0000-0000-000000000008', 'A) Do města Karlovy Vary.', false, 1),
  ('40000001-0000-0000-0000-000000000008', 'B) Do města Chomutov.', false, 2),
  ('40000001-0000-0000-0000-000000000008', 'C) Do města Louny.', true, 3),
  ('40000001-0000-0000-0000-000000000008', 'D) Do města Most.', false, 4),
  ('40000001-0000-0000-0000-000000000009', 'A) 20 000 Kč.', false, 1),
  ('40000001-0000-0000-0000-000000000009', 'B) 30 000 Kč.', true, 2),
  ('40000001-0000-0000-0000-000000000009', 'C) 35 000 Kč.', false, 3),
  ('40000001-0000-0000-0000-000000000009', 'D) 48 000 Kč.', false, 4),
  ('40000001-0000-0000-0000-000000000010', 'A) V sobotu ve dne.', false, 1),
  ('40000001-0000-0000-0000-000000000010', 'B) V neděli ve dne.', false, 2),
  ('40000001-0000-0000-0000-000000000010', 'C) V sobotu v noci.', true, 3),
  ('40000001-0000-0000-0000-000000000010', 'D) V neděli v noci.', false, 4);

INSERT INTO public.question_options (question_id, text, is_correct, order_index)
SELECT q.question_id::uuid, o.text, o.order_index = q.correct_order, o.order_index
FROM (
  VALUES
    ('40000001-0000-0000-0000-000000000011', 7),
    ('40000001-0000-0000-0000-000000000012', 3),
    ('40000001-0000-0000-0000-000000000013', 5),
    ('40000001-0000-0000-0000-000000000014', 6),
    ('40000001-0000-0000-0000-000000000015', 2)
) AS q(question_id, correct_order)
CROSS JOIN (
  VALUES
    (1, 'A) běh'),
    (2, 'B) vaření'),
    (3, 'C) kreslení'),
    (4, 'D) sledování televize'),
    (5, 'E) čtení'),
    (6, 'F) plavání'),
    (7, 'G) fotografování'),
    (8, 'H) tanec')
) AS o(order_index, text);

INSERT INTO public.question_options (question_id, text, image_url, is_correct, order_index)
SELECT q.question_id::uuid, o.text, o.image_url, o.order_index = q.correct_order, o.order_index
FROM (
  VALUES
    ('40000001-0000-0000-0000-000000000016', 6),
    ('40000001-0000-0000-0000-000000000017', 1),
    ('40000001-0000-0000-0000-000000000018', 4),
    ('40000001-0000-0000-0000-000000000019', 2),
    ('40000001-0000-0000-0000-000000000020', 3)
) AS q(question_id, correct_order)
CROSS JOIN (
  VALUES
    (1, 'A', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-a.png'),
    (2, 'B', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-b.png'),
    (3, 'C', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-c.png'),
    (4, 'D', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-d.png'),
    (5, 'E', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-e.png'),
    (6, 'F', 'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/options/official-a2-2025/listening-task4-option-f.png')
) AS o(order_index, text, image_url);

UPDATE public.questions
SET
  correct_answer = CASE id
    WHEN '40000001-0000-0000-0000-000000000021' THEN 'Eva'
    WHEN '40000001-0000-0000-0000-000000000022' THEN 'čtvrtek'
    WHEN '40000001-0000-0000-0000-000000000023' THEN '28. dubna'
    WHEN '40000001-0000-0000-0000-000000000024' THEN 'Klášterní'
    WHEN '40000001-0000-0000-0000-000000000025' THEN '932 504'
    ELSE correct_answer
  END,
  accepted_answers = CASE id
    WHEN '40000001-0000-0000-0000-000000000021' THEN ARRAY['eva']
    WHEN '40000001-0000-0000-0000-000000000022' THEN ARRAY['Čtvrtek', 'ctvrtek']
    WHEN '40000001-0000-0000-0000-000000000023' THEN ARRAY['28. 4.', '28 dubna', '28. dubna', 'dvacátého osmého dubna']
    WHEN '40000001-0000-0000-0000-000000000024' THEN ARRAY['klášterní', 'Klasterni']
    WHEN '40000001-0000-0000-0000-000000000025' THEN ARRAY['932504', '932 504', '773932504', '773 932 504']
    ELSE accepted_answers
  END
WHERE id IN (
  '40000001-0000-0000-0000-000000000021',
  '40000001-0000-0000-0000-000000000022',
  '40000001-0000-0000-0000-000000000023',
  '40000001-0000-0000-0000-000000000024',
  '40000001-0000-0000-0000-000000000025'
);

-- ── SPEAKING ───────────────────────────────────────────────────────────────

INSERT INTO public.questions (
  id, section_id, type, skill, prompt, intro_image_url, correct_answer, explanation, points, order_index
) VALUES
  ('50000001-0000-0000-0000-000000000001', 'bbbbbbbb-2222-0000-0000-000000000004', 'speaking', 'speaking', $$ÚLOHA 1 – Odpovědi na otázky

Téma 1: Život v České republice
- Kde se vám v České republice nejvíce líbí a proč?
- Které hory v České republice jste už navštívil/a?
- Kam v České republice pojedete v nejbližší době?
- Které místo v České republice navštěvují turisté nejvíce?

Téma 2: Počasí
- Ve kterém měsíci v Česku často sněží a mrzne?
- Jaké počasí máte rád/a a proč?
- Kdy naposledy pršelo?
- Jaké počasí bude zítra?

Yêu cầu: trả lời thành câu đầy đủ, rõ ràng, bằng tiếng Séc.$$,
NULL,
$$Rubric:
- Trả lời đủ 8 câu, bám đúng 2 chủ đề.
- Mỗi câu ngắn nhưng đầy đủ ý, dùng ngữ pháp A2 và phát âm dễ hiểu.
- Nội dung có tính cá nhân và phù hợp câu hỏi.$$,
$$Mẫu ý chính trong PDF: Poděbrady / Krkonoše a Šumava / pojedu do Brna / Praha / v lednu a únoru / mám rád teplé počasí / minulý čtvrtek / zítra bude zataženo a bude pršet.$$,
8,
1),
  ('50000001-0000-0000-0000-000000000002', 'bbbbbbbb-2222-0000-0000-000000000004', 'speaking', 'speaking', $$ÚLOHA 2 – Dialogy

Dialog 1: Jste v obchodě s obuví a potřebujete boty na sport. Zeptejte se na:
- velikost
- cenu
- materiál
- jednu vlastní doplňující otázku

Dialog 2: Jste na prohlídce bytu a chcete si byt pronajmout. Zeptejte se na:
- nájem
- možnost mít psa
- datum stěhování
- jednu vlastní doplňující otázku

Yêu cầu: tạo câu hỏi rõ ràng, lịch sự, bằng tiếng Séc.$$,
NULL,
$$Rubric:
- Thực hiện đủ 8 câu hỏi trên 2 thẻ.
- Câu hỏi tự nhiên, đúng vai giao tiếp.
- Có ít nhất 1 câu hỏi bổ sung hợp lý ở mỗi phần.
- Ngữ pháp, từ vựng và phản xạ ở mức A2.$$,
$$Mẫu câu trong PDF: Máte je ve velikosti 40? / Kolik stojí? / Jaký je to materiál? / Máte je i v jiné barvě? / Kolik budu platit za nájem? / Můžu mít v bytě psa? / Kdy se můžu nastěhovat? / Je v domě garáž?$$,
12,
2),
  ('50000001-0000-0000-0000-000000000003', 'bbbbbbbb-2222-0000-0000-000000000004', 'speaking', 'speaking', $$ÚLOHA 3 – Vyprávění podle obrázků

Popište příběh podle 4 obrázků: Co včera dělali otec a syn?
Téma: Nákup televize.

Yêu cầu:
- nói một mình bằng tiếng Séc
- dùng cả 4 obrázky
- mluvit v minulém čase.$$,
  'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/intro/official-a2-2025/speaking-task3-storyboard.png',
$$Rubric:
- Bao phủ đủ 4 tranh theo trình tự logic.
- Dùng minulý čas và từ nối cơ bản.
- Phát âm và mạch kể rõ ràng.$$,
$$Mẫu ý chính trong PDF: šli koupit televizi / nesli ji k autu a spadla otci na nohu / šli do nemocnice / pak se doma dívali na novou televizi.$$,
10,
3),
  ('50000001-0000-0000-0000-000000000004', 'bbbbbbbb-2222-0000-0000-000000000004', 'speaking', 'speaking', $$ÚLOHA 4 – Řešení situace

Bạn nói chuyện với giám khảo như bạn bè. Hai người cần chọn nơi gặp Věra vào ngày mai.
Chỉ được chọn từ 3 nơi trên hình.
Bạn phải:
- navrhnout vhodné místo
- reagovat na výhrady druhé osoby
- říct, proč je zvolené místo dobrý nápad
- domluvit se na jednom řešení

Yêu cầu: nói bằng tiếng Séc, rõ ràng và hợp tác.$$,
  'https://ripumojbqmesjpnswpqb.supabase.co/storage/v1/object/public/cms-assets/questions/intro/official-a2-2025/speaking-task4-choices.png',
$$Rubric:
- 7 bodů: chọn được 1 možnost z obrázku, phản hồi hợp lý và đưa ra lý do thuyết phục.
- 3 body: výslovnost / fonetika rõ ràng, dễ hiểu.
- Chỉ chọn đúng địa điểm xuất hiện trên hình.$$,
$$Mẫu ý trong PDF: kavárna je drahá / hospoda je hlučná / park je klidný a hezký na jaře.$$,
10,
4);
