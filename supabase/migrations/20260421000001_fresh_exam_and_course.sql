-- =============================================================================
-- Migration: Fresh Exam + Course (replaces all old seed data)
--
-- NEW EXAM: "Trvalý Pobyt — Bài thi thử (A2)"
--   Reading × 10 MCQ · Listening × 10 MCQ · Writing × 5 · Speaking × 5
--
-- NEW COURSE: "Tiếng Czech trong cuộc sống hàng ngày"
--   Module 1: Mua sắm & dịch vụ (Lesson 1–2)
--   Module 2: Sức khỏe & khẩn cấp (Lesson 3–4)
-- =============================================================================

-- ── STEP 1: Clear old content (order respects FK constraints) ────────────────

DELETE FROM public.ai_teacher_reviews;
DELETE FROM public.exam_results;
DELETE FROM public.exam_attempts;
DELETE FROM public.question_options;
DELETE FROM public.questions;
DELETE FROM public.exam_sections;
DELETE FROM public.exams;

DELETE FROM public.exercise_attempts;
DELETE FROM public.user_progress;
DELETE FROM public.lesson_block_exercises;
DELETE FROM public.lesson_blocks;
DELETE FROM public.ai_speaking_attempts;
DELETE FROM public.ai_writing_attempts;
DELETE FROM public.exercises;
DELETE FROM public.lessons;
DELETE FROM public.modules;
DELETE FROM public.courses;

-- ── STEP 2: New Exam ─────────────────────────────────────────────────────────

INSERT INTO public.exams (id, title, duration_minutes, is_active) VALUES
('00000000-0000-0000-0000-000000000001',
 'Trvalý Pobyt — Bài thi thử (A2)', 60, true);

INSERT INTO public.exam_sections (id, exam_id, skill, label, question_count, order_index) VALUES
('aaaaaaaa-1111-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','reading',  'Đọc hiểu (Čtení)',    10, 1),
('aaaaaaaa-1111-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','listening','Nghe hiểu (Poslech)', 10, 2),
('aaaaaaaa-1111-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','writing',  'Viết (Psaní)',          5, 3),
('aaaaaaaa-1111-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','speaking', 'Nói (Mluvení)',          5, 4);

-- ── READING questions (MCQ) ──────────────────────────────────────────────────

INSERT INTO public.questions
  (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index)
VALUES

-- R1: Giờ mở cửa cửa hàng
('00000001-0000-0000-0000-000000000001','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc biển tại cửa hàng:

ALBERT SUPERMARKET
Otevírací doba:
Pondělí – Pátek: 7:00 – 21:00
Sobota: 8:00 – 20:00
Neděle: 9:00 – 18:00

Bạn muốn đi mua sắm vào Chủ nhật lúc 19:00. Cửa hàng có còn mở không?',
 'b',
 '"Neděle" = Chủ nhật. Giờ mở cửa Chủ nhật: 9:00–18:00. Lúc 19:00 cửa hàng đã đóng vì quá 18:00.',
 1, 1),

-- R2: Thông báo thang máy hỏng
('00000001-0000-0000-0000-000000000002','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc thông báo trong tòa nhà:

POZOR!
Výtah je mimo provoz od pondělí 15. 4. do pátku 19. 4.
Oprava potrvá přibližně 5 dní.
Prosíme využívejte schodiště.
Děkujeme za pochopení.

Thông báo yêu cầu cư dân làm gì trong thời gian này?',
 'c',
 '"Výtah je mimo provoz" = thang máy tạm ngừng. "Využívejte schodiště" = dùng cầu thang bộ. Thang máy sẽ được sửa trong khoảng 5 ngày.',
 1, 2),

-- R3: Quảng cáo cho thuê căn hộ
('00000001-0000-0000-0000-000000000003','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc quảng cáo cho thuê nhà:

PRONÁJEM BYTU
Dispozice: 2+kk · Plocha: 52 m²
Lokalita: Praha 5 – Smíchov, 3. patro
Vybavení: plně zařízený, internet, parkování
Nájem: 15 500 Kč/měsíc + energie
Dostupný od: 1. 6. 2024
Kontakt: info@realitky.cz

Căn hộ này có bao nhiêu phòng và giá thuê là bao nhiêu?',
 'a',
 '"2+kk" = 2 phòng ngủ + bếp nhỏ (kuchyňský kout). Giá thuê "15 500 Kč/měsíc" = 15.500 Kč/tháng, chưa gồm tiền điện nước ("+ energie").',
 1, 3),

-- R4: Hướng dẫn dùng thuốc
('00000001-0000-0000-0000-000000000004','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc nhãn thuốc:

IBUPROFEN 400 mg — 20 tablet
Dávkování: 1 tableta 3× denně po jídle.
Nepřekračujte dávku 3 tablety za 24 hodin.
Neužívejte nalačno.
Uchovávejte mimo dosah dětí.
Použitelné do: 08/2026

Theo nhãn thuốc, bạn được uống tối đa bao nhiêu viên trong một ngày?',
 'b',
 '"Nepřekračujte dávku 3 tablety za 24 hodin" = không uống quá 3 viên trong 24 giờ. "Neužívejte nalačno" = không uống khi đói. "Po jídle" = sau bữa ăn.',
 1, 4),

-- R5: Phân loại rác
('00000001-0000-0000-0000-000000000005','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc hướng dẫn phân loại rác tại Czech:

TŘÍDĚNÍ ODPADU:
🟡 Žlutý kontejner → plasty, PET lahve, plechovky
🔵 Modrý kontejner → papír, noviny, karton
🟢 Zelený kontejner → sklo (láhve, sklenice)
⚫ Černý kontejner → směsný odpad (vše ostatní)

Bạn muốn vứt chai nhựa PET. Bạn bỏ vào thùng màu gì?',
 'a',
 '"PET lahve" (chai nhựa PET) → "Žlutý kontejner" (thùng vàng). Đây là quy tắc phân loại rác tiêu chuẩn tại Czech — nhớ thuộc màu sắc vì có thể bị phạt nếu bỏ rác sai thùng.',
 1, 5),

-- R6: Lịch tàu hỏa
('00000001-0000-0000-0000-000000000006','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc bảng lịch tàu:

JÍZDNÍ ŘÁD — Praha hl.n. → Brno hl.n.
Os 1201:  06:15 → 09:22  (Přímý spoj)
IC 502:   07:30 → 09:45  (Přímý spoj, místenka nutná)
R 857:    08:00 → 10:55  (Přestup v Pardubicích)
Ex 1010:  09:15 → 11:30  (Přímý spoj)

Bạn cần đến Brno trước 10:00 và muốn đi tàu thẳng (không chuyển tàu). Bạn nên đi chuyến nào?',
 'b',
 '"Přímý spoj" = tàu thẳng (không chuyển). "Přestup" = phải chuyển tàu. Chuyến IC 502 (7:30 → 9:45) đến trước 10:00 và là tàu thẳng — nhưng cần "místenka" (vé chỗ đặt trước).',
 1, 6),

-- R7: Thẻ bảo hiểm y tế
('00000001-0000-0000-0000-000000000007','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc thông tin trên thẻ bảo hiểm y tế:

PRŮKAZ POJIŠTĚNCE
Všeobecná zdravotní pojišťovna ČR (VZP)
Pojištěnec: NGUYEN VAN AN
Číslo pojištěnce: 850315/1234
Platnost: do 31. 12. 2025
Pojistitel: VZP ČR, IČO 41197518

Thẻ này có giá trị đến khi nào?',
 'c',
 '"Platnost: do 31. 12. 2025" = có giá trị đến 31 tháng 12 năm 2025. "VZP" (Všeobecná zdravotní pojišťovna) là công ty bảo hiểm y tế lớn nhất Czech. Khi hết hạn, bạn cần gia hạn tại văn phòng VZP.',
 1, 7),

-- R8: Thông báo lớp học tiếng Czech
('00000001-0000-0000-0000-000000000008','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc thông báo đăng ký học tiếng Czech:

KURZY ČEŠTINY PRO CIZINCE — PODZIM 2024
Úroveň A1 (začátečníci): Po, St 18:00–19:30
Úroveň A2 (mírně pokročilí): Út, Čt 17:30–19:00
Úroveň B1 (středně pokročilí): Pá 16:00–19:00
Cena: 3 500 Kč / semestr
Přihlášky: do 30. září 2024 na reception@czechschool.cz

Bạn đang ở trình độ A2 và muốn đăng ký. Bạn học vào những ngày nào trong tuần?',
 'd',
 '"Úroveň A2: Út, Čt" — Út = Úterý (Thứ Ba), Čt = Čtvrtek (Thứ Năm). Học từ 17:30–19:00. Lưu ý: hạn đăng ký là 30 tháng 9 và học phí 3.500 Kč/kỳ.',
 1, 8),

-- R9: Quy định về số khẩn cấp
('00000001-0000-0000-0000-000000000009','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc thông tin về số điện thoại khẩn cấp tại Czech:

DŮLEŽITÁ TELEFONNÍ ČÍSLA:
112 — Evropské tísňové volání (vše)
150 — Hasiči (požár, záchrana)
155 — Záchranná služba (zdravotní pomoc)
158 — Policie ČR
156 — Obecní / Městská policie

Nhà hàng xóm bị ngã và bất tỉnh. Bạn gọi số nào?',
 'b',
 '"Záchranná služba" (số 155) = cấp cứu y tế — gọi khi cần hỗ trợ sức khỏe khẩn cấp. Số 112 cũng có thể gọi (điều phối tất cả), nhưng số 155 là trực tiếp nhất cho trường hợp y tế.',
 1, 9),

-- R10: Hóa đơn điện nước
('00000001-0000-0000-0000-000000000010','aaaaaaaa-1111-0000-0000-000000000001','mcq','reading',
 'Đọc thông báo thanh toán hóa đơn:

FAKTURA — ČEZ DISTRIBUCE
Zákazník: Nguyen Van An
Číslo faktury: 2024-0089234
Fakturované období: 1. 1. – 31. 3. 2024
Celková částka: 4 280 Kč
Splatnost: do 15. dubna 2024
Způsob platby: bankovní převod
Číslo účtu: 123456789/0800

Nếu không thanh toán trước ngày 15 tháng 4, điều gì có thể xảy ra?',
 'c',
 '"Splatnost: do 15. dubna 2024" = hạn thanh toán ngày 15/4/2024. Nếu không trả đúng hạn, công ty điện có thể tính lãi phạt (penále) hoặc ngắt điện. "Bankovní převod" = chuyển khoản ngân hàng.',
 1, 10);

-- Reading options
INSERT INTO public.question_options (question_id, text, is_correct, order_index) VALUES
-- R1
('00000001-0000-0000-0000-000000000001','Có, mở cửa đến 21:00',false,1),
('00000001-0000-0000-0000-000000000001','Không, đã đóng cửa sau 18:00',true,2),
('00000001-0000-0000-0000-000000000001','Có, mở cửa đến 20:00',false,3),
('00000001-0000-0000-0000-000000000001','Không có thông tin về Chủ nhật',false,4),
-- R2
('00000001-0000-0000-0000-000000000002','Chờ thang máy được sửa',false,1),
('00000001-0000-0000-0000-000000000002','Liên hệ ban quản lý tòa nhà',false,2),
('00000001-0000-0000-0000-000000000002','Dùng cầu thang bộ thay thế',true,3),
('00000001-0000-0000-0000-000000000002','Không vào tòa nhà trong 5 ngày',false,4),
-- R3
('00000001-0000-0000-0000-000000000003','2 phòng ngủ + bếp nhỏ, 15.500 Kč/tháng',true,1),
('00000001-0000-0000-0000-000000000003','1 phòng ngủ + bếp, 15.500 Kč/tháng',false,2),
('00000001-0000-0000-0000-000000000003','2 phòng ngủ + bếp nhỏ, 52.000 Kč/tháng',false,3),
('00000001-0000-0000-0000-000000000003','3 phòng ngủ, 15.500 Kč/tháng',false,4),
-- R4
('00000001-0000-0000-0000-000000000004','2 viên',false,1),
('00000001-0000-0000-0000-000000000004','3 viên',true,2),
('00000001-0000-0000-0000-000000000004','4 viên',false,3),
('00000001-0000-0000-0000-000000000004','6 viên',false,4),
-- R5
('00000001-0000-0000-0000-000000000005','Thùng vàng',true,1),
('00000001-0000-0000-0000-000000000005','Thùng xanh dương',false,2),
('00000001-0000-0000-0000-000000000005','Thùng xanh lá',false,3),
('00000001-0000-0000-0000-000000000005','Thùng đen',false,4),
-- R6
('00000001-0000-0000-0000-000000000006','Os 1201 (6:15 → 9:22)',false,1),
('00000001-0000-0000-0000-000000000006','IC 502 (7:30 → 9:45)',true,2),
('00000001-0000-0000-0000-000000000006','R 857 (8:00 → 10:55)',false,3),
('00000001-0000-0000-0000-000000000006','Ex 1010 (9:15 → 11:30)',false,4),
-- R7
('00000001-0000-0000-0000-000000000007','Đến 31/12/2024',false,1),
('00000001-0000-0000-0000-000000000007','Đến 31/3/2025',false,2),
('00000001-0000-0000-0000-000000000007','Đến 31/12/2025',true,3),
('00000001-0000-0000-0000-000000000007','Vĩnh viễn (không hết hạn)',false,4),
-- R8
('00000001-0000-0000-0000-000000000008','Thứ Hai và Thứ Tư',false,1),
('00000001-0000-0000-0000-000000000008','Thứ Sáu',false,2),
('00000001-0000-0000-0000-000000000008','Thứ Hai và Thứ Tư',false,3),
('00000001-0000-0000-0000-000000000008','Thứ Ba và Thứ Năm',true,4),
-- R9
('00000001-0000-0000-0000-000000000009','158 (Policie ČR)',false,1),
('00000001-0000-0000-0000-000000000009','155 (Záchranná služba)',true,2),
('00000001-0000-0000-0000-000000000009','150 (Hasiči)',false,3),
('00000001-0000-0000-0000-000000000009','156 (Obecní policie)',false,4),
-- R10
('00000001-0000-0000-0000-000000000010','Hóa đơn sẽ tự động gia hạn',false,1),
('00000001-0000-0000-0000-000000000010','Bạn nhận được chiết khấu',false,2),
('00000001-0000-0000-0000-000000000010','Có thể bị phạt lãi hoặc ngắt điện',true,3),
('00000001-0000-0000-0000-000000000010','Không có hậu quả gì',false,4);


-- ── LISTENING questions (MCQ) ────────────────────────────────────────────────

INSERT INTO public.questions
  (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index)
VALUES

-- L1: Gọi điện đặt lịch bác sĩ
('00000002-0000-0000-0000-000000000001','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe đoạn hội thoại qua điện thoại:

Lễ tân: "Ordinace doktora Nováka, dobrý den."
Bệnh nhân: "Dobrý den, chtěl bych si objednat termín."
Lễ tân: "Kdy by vám to vyhovovalo?"
Bệnh nhân: "Nejdříve ve čtvrtek odpoledne, nebo v pátek."
Lễ tân: "Ve čtvrtek máme volné místo ve 14:30. Hodí se vám to?"
Bệnh nhân: "Ano, to je perfektní."

Bệnh nhân hẹn gặp bác sĩ vào ngày và giờ nào?',
 'b',
 '"Ve čtvrtek ve 14:30" = Thứ Năm lúc 14:30. "Objednat si termín" = đặt lịch hẹn. "Hodí se vám to?" = Thời gian đó có phù hợp không? "Ano, to je perfektní" = Vâng, tuyệt vời.',
 1, 1),

-- L2: Thông báo thời tiết trên đài
('00000002-0000-0000-0000-000000000002','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe dự báo thời tiết trên đài phát thanh:

"Dobré ráno, sledujte naši předpověď počasí na dnešní den. Praha a střední Čechy: dopoledne oblačno, odpoledne přeháňky a bouřky. Teplota kolem 18 stupňů. Doporučujeme vzít si deštník. Jihočeský kraj a Morava: převážně slunečno, teploty 22–25 stupňů."

Người nghe ở Praha nên làm gì hôm nay?',
 'a',
 '"Přeháňky a bouřky" = mưa rào và dông. "Doporučujeme vzít si deštník" = khuyên mang ô/dù. Praha buổi chiều có mưa, còn Moravia thì nắng (slunečno) ấm hơn.',
 1, 2),

-- L3: Thông báo tại siêu thị
('00000002-0000-0000-0000-000000000003','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe thông báo trong siêu thị:

"Vážení zákazníci, upozorňujeme, že dnes od 17 do 19 hodin probíhá akce: všechny výrobky z pekárny jsou se slevou 30 procent. Také připomínáme, že pokladny číslo 5 a 6 jsou dnes uzavřeny. Děkujeme za pochopení a přejeme příjemné nakupování."

Thông báo cho biết điều gì đang diễn ra trong siêu thị hôm nay?',
 'c',
 '"Výrobky z pekárny se slevou 30 %" = sản phẩm từ lò bánh mì giảm 30% từ 17–19 giờ. "Pokladny č. 5 a 6 jsou uzavřeny" = quầy thu ngân số 5 và 6 đóng cửa. "Zákazníci" = khách hàng.',
 1, 3),

-- L4: Thông báo tại ga tàu
('00000002-0000-0000-0000-000000000004','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe thông báo tại nhà ga:

"Vážení cestující, vlak číslo IC 504 z Prahy do Brna, odjezd v 10:30, přijede s přibližně dvacetiminutovým zpožděním. Odjezd je přesunut na 10:50. Vlak odjíždí z nástupiště číslo dvě. Omlouváme se za způsobené komplikace."

Chuyến tàu IC 504 đến Brno sẽ thực sự khởi hành lúc mấy giờ và từ sân ga nào?',
 'd',
 '"Dvacetminutové zpoždění" = trễ 20 phút. 10:30 + 20 phút = 10:50. "Nástupiště číslo dvě" = sân ga số 2. "Omlouváme se za komplikace" = xin lỗi vì bất tiện.',
 1, 4),

-- L5: Thông báo tự động của úřad
('00000002-0000-0000-0000-000000000005','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe tin nhắn thoại tự động của cơ quan:

"Dobrý den, dovolali jste se na Odbor cizinecké policie Praha. Naše úřední hodiny jsou pondělí a středa od 8 do 17 hodin, úterý a čtvrtek od 8 do 12 hodin. V pátek je úřad uzavřen. Pro objednání termínu stiskněte jedničku. Pro informace o dokladech stiskněte dvojku. Pro opakování stiskněte hvězdičku."

Nếu bạn muốn đặt lịch hẹn, bạn nhấn phím nào?',
 'a',
 '"Pro objednání termínu stiskněte jedničku" = Để đặt lịch hẹn, nhấn số 1. "Odbor cizinecké policie" = Phòng cảnh sát ngoại kiều. Thứ Sáu cơ quan này đóng cửa (uzavřen).',
 1, 5),

-- L6: Dược sĩ hướng dẫn dùng thuốc
('00000002-0000-0000-0000-000000000006','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe dược sĩ hướng dẫn:

"Tady máte předepsané léky. Amoxicilin berete třikrát denně po jídle, vždy ve stejnou dobu. Je důležité dokončit celý kurz, i když se budete cítit lépe. Nesmíte pít alkohol po dobu léčby. Máte nějaké otázky?"

Điều gì KHÔNG được phép làm khi đang uống thuốc Amoxicilin?',
 'b',
 '"Nesmíte pít alkohol po dobu léčby" = không được uống rượu trong thời gian điều trị. "Dokončit celý kurz" = uống hết cả liệu trình, dù cảm thấy khỏe hơn. "Po jídle" = sau bữa ăn.',
 1, 6),

-- L7: Hướng dẫn trên xe buýt
('00000002-0000-0000-0000-000000000007','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe thông báo trên xe buýt:

"Vážení cestující, připomínáme, že v tomto voze platí přísný zákaz kouření. Prosíme, nepouštějte hlasitou hudbu bez sluchátek a uvolněte místa pro těhotné ženy, seniory a cestující s kočárky. Lístky je nutné označit hned po nástupu. Děkujeme."

Hành khách PHẢI làm gì ngay sau khi lên xe?',
 'c',
 '"Lístky je nutné označit hned po nástupu" = vé phải được xác nhận (bấm máy) ngay sau khi lên xe. "Zákaz kouření" = cấm hút thuốc. "Uvolnit místa" = nhường chỗ ngồi.',
 1, 7),

-- L8: Cuộc trò chuyện về công việc
('00000002-0000-0000-0000-000000000008','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe đoạn hội thoại giữa người quản lý và nhân viên:

Quản lý: "Potřebuju, abyste zítra přišli o hodinu dřív, v sedm ráno."
Nhân viên: "A proč? Máme něco mimořádného?"
Quản lý: "Ano, přijíždí zákazník z Německa a musíme připravit prezentaci."
Nhân viên: "Dobře, budu tam v sedm."

Tại sao nhân viên phải đến sớm hơn vào ngày mai?',
 'a',
 '"Přijíždí zákazník z Německa" = có khách hàng từ Đức đến. "Připravit prezentaci" = chuẩn bị thuyết trình. "O hodinu dřív" = sớm hơn một tiếng. Giờ thông thường là 8:00, ngày mai đến lúc 7:00.',
 1, 8),

-- L9: Hàng xóm phàn nàn về tiếng ồn
('00000002-0000-0000-0000-000000000009','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe hàng xóm nói chuyện tại cửa:

"Dobrý večer, já jsem váš soused z bytu číslo 12. Omlouvám se za obtěžování, ale přišel jsem vám říct, že od vás slyšíme poměrně hlasitou hudbu. Víte, máme doma malé dítě, které teď spí. Bylo by možné trochu ztlumit? Moc bychom vám byli vděčni."

Hàng xóm yêu cầu điều gì?',
 'd',
 '"Ztlumit hudbu" = vặn nhỏ âm nhạc lại. "Obtěžovat" = làm phiền. "Malé dítě spí" = đứa trẻ nhỏ đang ngủ. "Byli bychom vám vděčni" = chúng tôi sẽ rất biết ơn bạn.',
 1, 9),

-- L10: Hướng dẫn khẩn cấp
('00000002-0000-0000-0000-000000000010','aaaaaaaa-1111-0000-0000-000000000002','mcq','listening',
 '[Poslech] Nghe hướng dẫn thoát hiểm trong tòa nhà:

"Pozor, pozor! Byl vyhlášen požární poplach. Ihned opusťte budovu nejbližším nouzovým východem. Výtahy nepoužívejte! Sraz je na parkovišti před budovou. Pokud nemůžete opustit místnost, zavřete dveře a zavolejte 150."

Khi có báo động cháy, bạn KHÔNG được làm gì?',
 'b',
 '"Výtahy nepoužívejte!" = không dùng thang máy! Đây là quy tắc quan trọng trong thoát hiểm — thang máy có thể mất điện hoặc kẹt. "Nouzový východ" = cửa thoát hiểm. "Požární poplach" = báo động cháy.',
 1, 10);

-- Listening options
INSERT INTO public.question_options (question_id, text, is_correct, order_index) VALUES
-- L1
('00000002-0000-0000-0000-000000000001','Thứ Tư lúc 14:30',false,1),
('00000002-0000-0000-0000-000000000001','Thứ Năm lúc 14:30',true,2),
('00000002-0000-0000-0000-000000000001','Thứ Sáu lúc 14:30',false,3),
('00000002-0000-0000-0000-000000000001','Thứ Năm lúc 13:30',false,4),
-- L2
('00000002-0000-0000-0000-000000000002','Mang ô vì buổi chiều có mưa',true,1),
('00000002-0000-0000-0000-000000000002','Mặc áo ấm vì trời lạnh',false,2),
('00000002-0000-0000-0000-000000000002','Ra ngoài sớm vì buổi chiều nắng gắt',false,3),
('00000002-0000-0000-0000-000000000002','Không cần lo vì Praha hôm nay nắng đẹp',false,4),
-- L3
('00000002-0000-0000-0000-000000000003','Tất cả sản phẩm giảm 30%',false,1),
('00000002-0000-0000-0000-000000000003','Siêu thị đóng cửa lúc 17:00',false,2),
('00000002-0000-0000-0000-000000000003','Bánh mì giảm 30% từ 17–19h, quầy 5 & 6 đóng',true,3),
('00000002-0000-0000-0000-000000000003','Siêu thị mở thêm quầy thu ngân mới',false,4),
-- L4
('00000002-0000-0000-0000-000000000004','10:30, sân ga số 4',false,1),
('00000002-0000-0000-0000-000000000004','10:50, sân ga số 4',false,2),
('00000002-0000-0000-0000-000000000004','10:30, sân ga số 2',false,3),
('00000002-0000-0000-0000-000000000004','10:50, sân ga số 2',true,4),
-- L5
('00000002-0000-0000-0000-000000000005','Nhấn số 1',true,1),
('00000002-0000-0000-0000-000000000005','Nhấn số 2',false,2),
('00000002-0000-0000-0000-000000000005','Nhấn dấu *',false,3),
('00000002-0000-0000-0000-000000000005','Gọi lại vào giờ làm việc',false,4),
-- L6
('00000002-0000-0000-0000-000000000006','Uống thuốc sau khi ăn',false,1),
('00000002-0000-0000-0000-000000000006','Uống rượu bia',true,2),
('00000002-0000-0000-0000-000000000006','Dừng thuốc khi cảm thấy khỏe',false,3),
('00000002-0000-0000-0000-000000000006','Uống thuốc cùng một giờ mỗi ngày',false,4),
-- L7
('00000002-0000-0000-0000-000000000007','Nhường chỗ cho phụ nữ mang thai',false,1),
('00000002-0000-0000-0000-000000000007','Tắt nhạc hoàn toàn',false,2),
('00000002-0000-0000-0000-000000000007','Bấm xác nhận vé ngay khi lên xe',true,3),
('00000002-0000-0000-0000-000000000007','Không hút thuốc trên xe',false,4),
-- L8
('00000002-0000-0000-0000-000000000008','Có khách hàng từ Đức đến và cần chuẩn bị thuyết trình',true,1),
('00000002-0000-0000-0000-000000000008','Công ty có họp quan trọng',false,2),
('00000002-0000-0000-0000-000000000008','Phải hoàn thành báo cáo sớm',false,3),
('00000002-0000-0000-0000-000000000008','Quản lý yêu cầu không có lý do',false,4),
-- L9
('00000002-0000-0000-0000-000000000009','Mở cửa sổ thông gió',false,1),
('00000002-0000-0000-0000-000000000009','Tắt đèn trong nhà',false,2),
('00000002-0000-0000-0000-000000000009','Chơi nhạc thêm một chút rồi tắt',false,3),
('00000002-0000-0000-0000-000000000009','Vặn nhỏ âm nhạc lại',true,4),
-- L10
('00000002-0000-0000-0000-000000000010','Dùng cửa thoát hiểm',false,1),
('00000002-0000-0000-0000-000000000010','Sử dụng thang máy',true,2),
('00000002-0000-0000-0000-000000000010','Tập trung tại bãi đỗ xe',false,3),
('00000002-0000-0000-0000-000000000010','Gọi số 150 nếu không thoát ra được',false,4);


-- ── WRITING questions (open text) ────────────────────────────────────────────

INSERT INTO public.questions
  (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index)
VALUES

('00000003-0000-0000-0000-000000000001','aaaaaaaa-1111-0000-0000-000000000003','writing','writing',
 'Napište formální email na Odbor cizinecké policie (50–80 slov).

Žádáte o informaci:
• Jaké dokumenty potřebujete pro žádost o trvalý pobyt
• Jaká je aktuální lhůta pro vyřízení
• Zda je možné podat žádost online nebo musíte přijít osobně',
 null,
 'Hodnotí se: formální oslovení (Vážení/Dobrý den), jasné otázky k požadovaným tématům, správné rozloučení (S pozdravem). Příklad: "Dobrý den, rád bych se zeptal, jaké dokumenty jsou potřeba k žádosti o trvalý pobyt, jak dlouho trvá vyřízení a zda je možné podat žádost online. Předem děkuji za odpověď. S pozdravem, Nguyen Van An."',
 2, 1),

('00000003-0000-0000-0000-000000000002','aaaaaaaa-1111-0000-0000-000000000003','writing','writing',
 'Napište omluvný dopis třídnímu učiteli svého dítěte (40–60 slov).

Vaše dítě (Minh, 3. třída) nemůže přijít do školy příští týden v pondělí a úterý z důvodu plánovaného lékařského zákroku. Požádejte o zadání domácích úkolů.',
 null,
 'Hodnotí se: formální styl, uvedení jména dítěte a třídy, zdůvodnění absence, žádost o domácí úkoly, vhodný pozdrav a rozloučení. Příklad: "Vážená paní učitelko, píšu Vám, abych Vás informoval/a, že mé dítě Minh ze 3. třídy nebude ve škole v pondělí a úterý kvůli lékařskému zákroku. Prosím o zaslání domácích úkolů. Děkuji. S pozdravem, Nguyen Van An."',
 2, 2),

('00000003-0000-0000-0000-000000000003','aaaaaaaa-1111-0000-0000-000000000003','writing','writing',
 'Popište svůj typický pracovní týden (60–80 slov).

Zahrňte:
• Kdy vstáváte a jak se dostáváte do práce
• Co děláte v práci
• Jak trávíte volný čas po práci
• Co děláte o víkendu',
 null,
 'Hodnotí se: chronologická struktura, správné použití časových výrazů (ráno, odpoledne, večer, v pondělí, o víkendu), správné tvary sloves v přítomném čase, rozmanitost slovní zásoby.',
 2, 3),

('00000003-0000-0000-0000-000000000004','aaaaaaaa-1111-0000-0000-000000000003','writing','writing',
 'Napište stížnost pronajímateli bytu (60–80 slov).

Situace: Bydlíte v pronajatém bytě 3 měsíce. Topení v ložnici nefunguje od října. Pronajímatel nereaguje na telefonáty. Žádáte o okamžité opravení nebo slevu z nájmu.',
 null,
 'Hodnotí se: formální tón, jasný popis problému, zmínka o délce problému a pokusech o kontakt, konkrétní požadavek (oprava nebo sleva). Klíčová slovní zásoba: topení = heating, nefunguje = does not work, žádám o opravu = I request repair, sleva z nájmu = rent reduction.',
 2, 4),

('00000003-0000-0000-0000-000000000005','aaaaaaaa-1111-0000-0000-000000000003','writing','writing',
 'Napište krátký text (50–70 slov) o tom, proč chcete zůstat v České republice natrvalo.

Zmiňte:
• Jak dlouho zde žijete
• Co se vám na ČR líbí
• Vaše plány do budoucna (práce, rodina, integrace)',
 null,
 'Hodnotí se: osobní a přesvědčivý tón, správné použití sloves chtít/mít v úmyslu/plánovat, vyjádření pocitů a motivace. Toto téma je velmi typické pro ústní část zkoušky Trvalý pobyt.',
 2, 5);


-- ── SPEAKING questions ───────────────────────────────────────────────────────

INSERT INTO public.questions
  (id, section_id, type, skill, prompt, correct_answer, explanation, points, order_index)
VALUES

('00000004-0000-0000-0000-000000000001','aaaaaaaa-1111-0000-0000-000000000004','speaking','speaking',
 'Představte svou rodinu. (1–2 minuty)

Řekněte:
• Kolik máte členů rodiny a kde žijí
• Čím se zabývá váš partner/partnerka nebo rodiče
• Jaké máte rodinné tradice nebo zvyky
• Co děláte společně ve volném čase',
 null,
 'Hodnotí se: plynulost, správné použití přivlastňovacích zájmen (můj, moje, naše), slovní zásoba k rodině a volnočasovým aktivitám, logická struktura odpovědi.',
 2, 1),

('00000004-0000-0000-0000-000000000002','aaaaaaaa-1111-0000-0000-000000000004','speaking','speaking',
 'Popište místo, kde bydlíte. (1–2 minuty)

Zahrňte:
• V jakém městě / čtvrti žijete
• Jak vypadá váš byt nebo dům
• Co se vám na lokalitě líbí nebo nelíbí
• Jaké jsou možnosti dopravy a služby v okolí',
 null,
 'Hodnotí se: popis prostředí a místa (přívlastky, lokál — v/na + 6. pád), kladné i záporné hodnocení, slovní zásoba k bydlení a dopravě.',
 2, 2),

('00000004-0000-0000-0000-000000000003','aaaaaaaa-1111-0000-0000-000000000004','speaking','speaking',
 'Vyprávějte o své pracovní nebo studijní zkušenosti v České republice. (1–2 minuty)

Řekněte:
• Kde pracujete nebo studujete a jak dlouho
• Jaká je vaše pracovní náplň nebo studijní obor
• S čím vám pomohla znalost češtiny v práci / škole
• Jaké jsou vaše profesní cíle do budoucna',
 null,
 'Hodnotí se: správné použití minulého a přítomného času, odborná slovní zásoba, vyjádření budoucnosti (chci, plánuji, budu).',
 2, 3),

('00000004-0000-0000-0000-000000000004','aaaaaaaa-1111-0000-0000-000000000004','speaking','speaking',
 'Popište českou tradici nebo svátek, který vás zaujal. (1–2 minuty)

Například: Vánoce, Velikonoce, Masopust, Den svatého Mikuláše, nebo jiný.

Řekněte:
• Co to je a kdy se slaví
• Jak se slaví (zvyky, jídlo, aktivity)
• Jak jste se o tradici dozvěděli
• Co si o ní myslíte',
 null,
 'Hodnotí se: znalost české kultury, správné použití minulého času pro vyprávění (slavil jsem, viděl jsem), vyjádření názoru (myslím, že / líbí se mi / překvapilo mě).',
 2, 4),

('00000004-0000-0000-0000-000000000005','aaaaaaaa-1111-0000-0000-000000000004','speaking','speaking',
 'Simulace: Jste na úřadě a zjistíte, že váš formulář byl ztracen. (1–2 minuty)

Situace: Před třemi týdny jste podali žádost o prodloužení pobytu. Dnes voláte na úřad a dozvíte se, že vaše žádost v systému není.

Řekněte, jak byste situaci řešili:
• Co byste řekli úředníkovi
• Jaké doklady byste nabídli jako důkaz podání
• Jak byste požádali o nápravu',
 null,
 'Hodnotí se: formální styl komunikace, klidný a asertivní tón, použití podmíněného způsobu (mohl bych, chtěl bych), slovní zásoba k administrativním procesům.',
 2, 5);


-- ═════════════════════════════════════════════════════════════════════════════
-- STEP 3: New Course — "Tiếng Czech trong cuộc sống hàng ngày"
-- 2 modules · 4 lessons · 24 exercises · 24 lesson_blocks
-- ═════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_course_id uuid := gen_random_uuid();
  v_mod1_id   uuid := gen_random_uuid();
  v_mod2_id   uuid := gen_random_uuid();
  v_les1_id   uuid := gen_random_uuid();
  v_les2_id   uuid := gen_random_uuid();
  v_les3_id   uuid := gen_random_uuid();
  v_les4_id   uuid := gen_random_uuid();

  -- Lesson 1 exercises
  v_l1e1 uuid := gen_random_uuid(); v_l1e2 uuid := gen_random_uuid();
  v_l1e3 uuid := gen_random_uuid(); v_l1e4 uuid := gen_random_uuid();
  v_l1e5 uuid := gen_random_uuid(); v_l1e6 uuid := gen_random_uuid();
  v_l1b1 uuid := gen_random_uuid(); v_l1b2 uuid := gen_random_uuid();
  v_l1b3 uuid := gen_random_uuid(); v_l1b4 uuid := gen_random_uuid();
  v_l1b5 uuid := gen_random_uuid(); v_l1b6 uuid := gen_random_uuid();

  -- Lesson 2 exercises + block IDs
  v_l2e1 uuid := gen_random_uuid(); v_l2e2 uuid := gen_random_uuid();
  v_l2e3 uuid := gen_random_uuid(); v_l2e4 uuid := gen_random_uuid();
  v_l2e5 uuid := gen_random_uuid(); v_l2e6 uuid := gen_random_uuid();
  v_l2b1 uuid := gen_random_uuid(); v_l2b2 uuid := gen_random_uuid();
  v_l2b3 uuid := gen_random_uuid(); v_l2b4 uuid := gen_random_uuid();
  v_l2b5 uuid := gen_random_uuid(); v_l2b6 uuid := gen_random_uuid();

  -- Lesson 3 exercises + block IDs
  v_l3e1 uuid := gen_random_uuid(); v_l3e2 uuid := gen_random_uuid();
  v_l3e3 uuid := gen_random_uuid(); v_l3e4 uuid := gen_random_uuid();
  v_l3e5 uuid := gen_random_uuid(); v_l3e6 uuid := gen_random_uuid();
  v_l3b1 uuid := gen_random_uuid(); v_l3b2 uuid := gen_random_uuid();
  v_l3b3 uuid := gen_random_uuid(); v_l3b4 uuid := gen_random_uuid();
  v_l3b5 uuid := gen_random_uuid(); v_l3b6 uuid := gen_random_uuid();

  -- Lesson 4 exercises + block IDs
  v_l4e1 uuid := gen_random_uuid(); v_l4e2 uuid := gen_random_uuid();
  v_l4e3 uuid := gen_random_uuid(); v_l4e4 uuid := gen_random_uuid();
  v_l4e5 uuid := gen_random_uuid(); v_l4e6 uuid := gen_random_uuid();
  v_l4b1 uuid := gen_random_uuid(); v_l4b2 uuid := gen_random_uuid();
  v_l4b3 uuid := gen_random_uuid(); v_l4b4 uuid := gen_random_uuid();
  v_l4b5 uuid := gen_random_uuid(); v_l4b6 uuid := gen_random_uuid();

BEGIN

-- ── COURSE ───────────────────────────────────────────────────────────────────
INSERT INTO public.courses
  (id, slug, title, description, skill, is_premium, order_index,
   instructor_name, instructor_bio, duration_days)
VALUES (
  v_course_id,
  'tieng-czech-hang-ngay',
  'Tiếng Czech trong cuộc sống hàng ngày',
  'Học tiếng Czech thực tế qua 4 tình huống thiết yếu trong cuộc sống: mua sắm tại siêu thị, giao dịch tại ngân hàng và bưu điện, khám bệnh, và xử lý các tình huống khẩn cấp. Mỗi bài học đều có từ vựng, ngữ pháp, luyện nghe, luyện đọc, luyện nói và luyện viết.',
  'speaking',
  false, 20,
  'Mgr. Pavel Dvořák',
  'Giảng viên tiếng Czech 8 năm kinh nghiệm tại Trung tâm ngôn ngữ Praha. Chuyên đào tạo người nước ngoài ở cấp độ A1–B1, đặc biệt tập trung vào tiếng Czech trong các tình huống hàng ngày.',
  28
);

-- ── MODULE 1: Mua sắm & dịch vụ ─────────────────────────────────────────────
INSERT INTO public.modules (id, course_id, title, description, order_index, is_locked)
VALUES (
  v_mod1_id, v_course_id,
  'Mua sắm & Dịch vụ',
  'Nắm vững ngôn ngữ cần thiết khi mua sắm hàng ngày, đến ngân hàng và bưu điện — những tình huống bạn sẽ gặp hàng tuần khi sống tại Czech.',
  1, false
);

-- ── LESSON 1: Tại siêu thị ───────────────────────────────────────────────────
INSERT INTO public.lessons
  (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les1_id, v_mod1_id,
  'Tại siêu thị',
  'Học cách tìm sản phẩm, hỏi nhân viên, đọc nhãn hàng, và thanh toán tại siêu thị Czech. Từ "kde najdu..." đến "mohu platit kartou?" — tất cả những gì bạn cần.',
  20, 1, 300
);

-- L1-E1: VOCAB MCQ — từ vựng siêu thị
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e1, 'mcq', 'vocabulary', 'beginner', 10, 10, '{
  "prompt": "''Pokladna'' trong siêu thị là gì?\n\nA. Kho hàng\nB. Quầy thu ngân\nC. Phòng bảo vệ\nD. Lối ra khẩn cấp",
  "explanation": "''Pokladna'' = quầy thu ngân (checkout). Khi thấy biển ''Pokladna'', đó là nơi bạn trả tiền. Ở Czech, siêu thị thường có ''samoobslužná pokladna'' (self-checkout) và ''pokladna s obsluhou'' (có nhân viên).",
  "options": [
    {"id": "a", "text": "Kho hàng", "is_correct": false},
    {"id": "b", "text": "Quầy thu ngân", "is_correct": true},
    {"id": "c", "text": "Phòng bảo vệ", "is_correct": false},
    {"id": "d", "text": "Lối ra khẩn cấp", "is_correct": false}
  ]
}');

-- L1-E2: GRAMMAR fill_blank — hỏi vị trí sản phẩm
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e2, 'fill_blank', 'grammar', 'beginner', 10, 10, '{
  "prompt": "Điền động từ đúng:\n\nPromiňte, kde ______ mléko?\n(Xin hỏi, sữa ở đâu?)\n\nGợi ý: najdu / hledám / kupuji",
  "correct_answer": "najdu",
  "explanation": "''Kde najdu mléko?'' = Tôi có thể tìm sữa ở đâu? Dùng ''najít'' (tìm thấy) khi hỏi vị trí sản phẩm.\n\nCác câu hỏi thường gặp tại siêu thị:\n• Kde najdu chléb? = Bánh mì ở đâu?\n• Je tady bezlepkové pečivo? = Có bánh mì không gluten không?\n• Kolik to stojí? = Cái này bao nhiêu tiền?"
}');

-- L1-E3: READING MCQ — đọc nhãn sản phẩm
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e3, 'mcq', 'reading', 'beginner', 10, 10, '{
  "prompt": "Đọc nhãn sản phẩm trên hộp sữa:\n\n┌───────────────────────────────┐\n│  TESCO PLNOTUČNÉ MLÉKO        │\n│  Obsah: 1 litr                │\n│  Tučnost: 3,5 %               │\n│  Trvanlivost: 4 dny po otevření│\n│  Uchovávejte v chladu (2–6°C) │\n│  Cena: 22,90 Kč               │\n└───────────────────────────────┘\n\nSau khi mở hộp, bạn nên dùng sữa này trong bao nhiêu ngày?",
  "explanation": "''Trvanlivost: 4 dny po otevření'' = hạn sử dụng sau khi mở: 4 ngày. ''Uchovávejte v chladu'' = bảo quản lạnh. ''Plnotučné'' = nguyên chất (full fat, 3,5%). Luôn chú ý ''trvanlivost'' trên nhãn thực phẩm Czech.",
  "options": [
    {"id": "a", "text": "1 ngày", "is_correct": false},
    {"id": "b", "text": "2 ngày", "is_correct": false},
    {"id": "c", "text": "4 ngày", "is_correct": true},
    {"id": "d", "text": "7 ngày", "is_correct": false}
  ]
}');

-- L1-E4: LISTENING MCQ — thanh toán tại quầy
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e4, 'mcq', 'listening', 'beginner', 10, 10, '{
  "prompt": "Nghe hội thoại tại quầy thu ngân:\n\nThu ngân: ''Dobrý den. To bude 347 korun a 50 haléřů.''\nKhách: ''Mohu platit kartou?''\nThu ngân: ''Samozřejmě. Přiložte kartu k terminálu, prosím.''\nKhách: ''Hotovo. Mohu dostat účtenku?''\nThu ngân: ''Ano, tady máte.''\n\nKhách muốn gì sau khi thanh toán?",
  "explanation": "''Mohu dostat účtenku?'' = Tôi có thể lấy hóa đơn không? ''Platit kartou'' = trả bằng thẻ. ''Přiložte kartu k terminálu'' = chạm thẻ vào máy. ''Samozřejmě'' = tất nhiên rồi. ''Hotovo'' = xong rồi.",
  "options": [
    {"id": "a", "text": "Đổi tiền lẻ", "is_correct": false},
    {"id": "b", "text": "Nhận hóa đơn", "is_correct": true},
    {"id": "c", "text": "Hỏi giá sản phẩm", "is_correct": false},
    {"id": "d", "text": "Đổi sản phẩm", "is_correct": false}
  ]
}');

-- L1-E5: SPEAKING — Mua sắm tại siêu thị
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e5, 'speaking', 'speaking', 'beginner', 20, 20, '{
  "prompt": "Tình huống: Bạn đang ở siêu thị và không tìm thấy dầu ăn (olej). Bạn hỏi một nhân viên siêu thị.\n\nHãy nói bằng tiếng Czech:\n• Chào và xin lỗi vì làm phiền\n• Hỏi dầu ăn ở khu vực nào\n• Cảm ơn khi nhận được hướng dẫn\n\nNói ít nhất 3–4 câu tự nhiên.",
  "explanation": "Câu mẫu:\n''Promiňte, mohl/mohla bych vás na něco zeptat? Hledám olej na vaření. Víte, ve kterém uličce ho najdu? Děkuji moc za pomoc.''\n\nTừ vựng:\n• Promiňte, mohl/mohla bych se zeptat? = Xin lỗi, tôi có thể hỏi không?\n• Hledám = tôi đang tìm\n• Ve které uličce? = Ở lối đi nào?\n• Děkuji moc = cảm ơn rất nhiều"
}');

-- L1-E6: WRITING — Viết danh sách mua sắm + ghi chú
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1e6, 'writing', 'writing', 'beginner', 20, 20, '{
  "prompt": "Viết danh sách mua sắm và ghi chú bằng tiếng Czech (30–50 từ).\n\nTình huống: Bạn đi siêu thị thay cho vợ/chồng. Họ nhờ bạn mua: sữa nguyên chất (1L), bánh mì trắng, 6 quả trứng, phô mai Eidam và nước cam (không đường). Nếu không có nước cam, mua nước táo.\n\nViết danh sách và ghi chú thay thế.",
  "explanation": "Danh sách mẫu:\n''Nákupní seznam:\n1. Plnotučné mléko (1 litr)\n2. Bílý chléb\n3. Vajíčka (6 kusů)\n4. Eidam sýr\n5. Pomerančová šťáva (bez cukru) – pokud není, kup jablečnou šťávu\n\nDěkuji!''\n\nTừ vựng:\n• nákupní seznam = danh sách mua sắm\n• pokud není = nếu không có\n• kusů = cái/quả (genitive plural)"
}');

-- Lesson 1 blocks
INSERT INTO public.lesson_blocks (id, lesson_id, type, order_index) VALUES
  (v_l1b1, v_les1_id, 'vocab',     1),
  (v_l1b2, v_les1_id, 'grammar',   2),
  (v_l1b3, v_les1_id, 'reading',   3),
  (v_l1b4, v_les1_id, 'listening', 4),
  (v_l1b5, v_les1_id, 'speaking',  5),
  (v_l1b6, v_les1_id, 'writing',   6);
INSERT INTO public.lesson_block_exercises (block_id, exercise_id, order_index) VALUES
  (v_l1b1, v_l1e1, 1), (v_l1b2, v_l1e2, 1), (v_l1b3, v_l1e3, 1),
  (v_l1b4, v_l1e4, 1), (v_l1b5, v_l1e5, 1), (v_l1b6, v_l1e6, 1);

-- ── LESSON 2: Tại ngân hàng và bưu điện ─────────────────────────────────────
INSERT INTO public.lessons
  (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les2_id, v_mod1_id,
  'Tại ngân hàng và bưu điện',
  'Học cách mở tài khoản ngân hàng, gửi tiền, hỏi về phí dịch vụ, và gửi bưu phẩm về Việt Nam — những kỹ năng ngôn ngữ thiết thực bạn cần ngay từ những tuần đầu tại Czech.',
  25, 2, 350
);

-- L2-E1: VOCAB MCQ — từ vựng ngân hàng
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e1, 'mcq', 'vocabulary', 'beginner', 10, 10, '{
  "prompt": "Nhân viên ngân hàng nói: ''Potřebuji váš doklad totožnosti a doklad o adrese.'' Họ đang yêu cầu gì?\n\nA. Số tài khoản và mã PIN\nB. Chứng minh danh tính và giấy tờ địa chỉ\nC. Hợp đồng lao động và bảng lương\nD. Hộ chiếu và thẻ cư trú",
  "explanation": "''Doklad totožnosti'' = giấy tờ chứng minh danh tính (CMND/hộ chiếu/thẻ cư trú). ''Doklad o adrese'' = giấy tờ chứng minh địa chỉ (hợp đồng thuê nhà, hóa đơn điện/nước). Khi mở tài khoản ngân hàng tại Czech, bạn thường cần cả hai loại giấy tờ này.",
  "options": [
    {"id": "a", "text": "Số tài khoản và mã PIN", "is_correct": false},
    {"id": "b", "text": "Chứng minh danh tính và giấy tờ địa chỉ", "is_correct": true},
    {"id": "c", "text": "Hợp đồng lao động và bảng lương", "is_correct": false},
    {"id": "d", "text": "Hộ chiếu và thẻ cư trú", "is_correct": false}
  ]
}');

-- L2-E2: GRAMMAR fill_blank — câu hỏi về phí dịch vụ
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e2, 'fill_blank', 'grammar', 'beginner', 10, 10, '{
  "prompt": "Điền từ thích hợp:\n\nKolik ______ měsíční poplatek za vedení účtu?\n(Phí quản lý tài khoản hàng tháng là bao nhiêu?)\n\nGợi ý: stojí / je / platí",
  "correct_answer": "stojí",
  "explanation": "''Kolik stojí...?'' = ...giá bao nhiêu / ...tốn bao nhiêu?\n\n''Stát'' (cost/price) là động từ dùng khi hỏi giá:\n• Kolik stojí tento produkt? = Sản phẩm này giá bao nhiêu?\n• Kolik stojí poplatek? = Phí là bao nhiêu?\n\n''Je'' cũng có thể dùng (''Jaký je poplatek?'' = Mức phí là bao nhiêu?) nhưng ''stojí'' tự nhiên hơn khi hỏi về chi phí cụ thể."
}');

-- L2-E3: READING MCQ — đọc điều khoản ngân hàng
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e3, 'mcq', 'reading', 'beginner', 10, 10, '{
  "prompt": "Đọc thông tin về tài khoản ngân hàng:\n\nÚČET SMART KONTO — České spořitelny\n✓ Vedení účtu: ZDARMA\n✓ Výběry z bankomatů ČS: ZDARMA\n✓ Výběry z bankomatů jiných bank: 39 Kč / výběr\n✓ Odchozí platba v rámci ČR: ZDARMA\n✓ Odchozí platba do zahraničí: 150 Kč\n✓ Internetové bankovnictví: ZDARMA\n\nBạn muốn rút tiền tại máy ATM của ngân hàng khác (không phải České spořitelna). Phí là bao nhiêu?",
  "explanation": "''Výběry z bankomatů jiných bank: 39 Kč / výběr'' = rút tiền tại ATM ngân hàng khác: 39 Kč mỗi lần rút. ''Zdarma'' = miễn phí. ''Vedení účtu zdarma'' = không mất phí quản lý tài khoản.",
  "options": [
    {"id": "a", "text": "Miễn phí", "is_correct": false},
    {"id": "b", "text": "39 Kč", "is_correct": true},
    {"id": "c", "text": "150 Kč", "is_correct": false},
    {"id": "d", "text": "Không thể rút được", "is_correct": false}
  ]
}');

-- L2-E4: LISTENING MCQ — tại bưu điện
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e4, 'mcq', 'listening', 'beginner', 10, 10, '{
  "prompt": "Nghe hội thoại tại bưu điện:\n\nNhân viên: ''Dobrý den, jak vám mohu pomoci?''\nKhách: ''Chtěl bych poslat balíček do Vietnamu.''\nNhân viên: ''Jak rychle to potřebujete doručit? Máme standardní doručení za 7–14 dní za 450 korun, nebo expres za 3–5 dní za 980 korun.''\nKhách: ''Standardní mi stačí, není to urgentní.''\nNhân viên: ''Dobře. Položte balíček na váhu, prosím.''\n\nKhách chọn phương thức gửi nào và tại sao?",
  "explanation": "''Standardní doručení'' = giao hàng tiêu chuẩn (7–14 ngày, 450 Kč). ''Expres'' = chuyển phát nhanh (3–5 ngày, 980 Kč). Khách chọn ''standardní'' vì ''není to urgentní'' = không gấp. ''Na váhu'' = lên cân.",
  "options": [
    {"id": "a", "text": "Expres vì cần nhanh", "is_correct": false},
    {"id": "b", "text": "Tiêu chuẩn vì không gấp", "is_correct": true},
    {"id": "c", "text": "Tiêu chuẩn vì rẻ hơn 450 Kč", "is_correct": false},
    {"id": "d", "text": "Khách chưa quyết định", "is_correct": false}
  ]
}');

-- L2-E5: SPEAKING — Tại ngân hàng
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e5, 'speaking', 'speaking', 'beginner', 20, 20, '{
  "prompt": "Tình huống: Bạn muốn mở tài khoản ngân hàng tại Czech. Bạn đến chi nhánh và nói chuyện với nhân viên.\n\nHãy nói bằng tiếng Czech:\n• Giải thích bạn muốn mở tài khoản\n• Hỏi những giấy tờ cần mang theo\n• Hỏi về phí quản lý tài khoản hàng tháng\n• Hỏi về thẻ ngân hàng (debitní karta)\n\nNói ít nhất 4–5 câu.",
  "explanation": "Câu mẫu:\n''Dobrý den, rád/ráda bych si otevřel/a nový bankovní účet. Jaké dokumenty potřebuji přinést? Kolik stojí vedení účtu? Je v ceně i debitní karta?''\n\nTừ vựng:\n• otevřít účet = mở tài khoản\n• bankovní účet = tài khoản ngân hàng\n• vedení účtu = phí quản lý tài khoản\n• debitní karta = thẻ ghi nợ\n• úrok = lãi suất"
}');

-- L2-E6: WRITING — Viết lệnh chuyển khoản
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2e6, 'writing', 'writing', 'beginner', 20, 20, '{
  "prompt": "Viết email cho ngân hàng (40–60 từ) bằng tiếng Czech để:\n• Thông báo bạn sẽ đi Việt Nam 3 tuần\n• Yêu cầu ngân hàng không chặn thẻ khi thấy giao dịch ở nước ngoài\n• Cung cấp số điện thoại liên hệ khi cần",
  "explanation": "Email mẫu:\n''Dobrý den,\ndovolte mi informovat vás, že od 10. do 31. srpna budu na cestě ve Vietnamu. Prosím, neblokujte mou kartu při zahraničních transakcích. V případě potřeby mě kontaktujte na čísle +420 777 123 456.\nDěkuji.\nS pozdravem, Nguyen Van An, č. účtu: 123456789/0800''\n\nTừ vựng:\n• neblokovat kartu = không chặn thẻ\n• zahraniční transakce = giao dịch nước ngoài\n• na cestě = đang đi du lịch"
}');

-- Lesson 2 blocks
INSERT INTO public.lesson_blocks (id, lesson_id, type, order_index) VALUES
  (v_l2b1, v_les2_id, 'vocab',     1),
  (v_l2b2, v_les2_id, 'grammar',   2),
  (v_l2b3, v_les2_id, 'reading',   3),
  (v_l2b4, v_les2_id, 'listening', 4),
  (v_l2b5, v_les2_id, 'speaking',  5),
  (v_l2b6, v_les2_id, 'writing',   6);
INSERT INTO public.lesson_block_exercises (block_id, exercise_id, order_index) VALUES
  (v_l2b1, v_l2e1, 1), (v_l2b2, v_l2e2, 1), (v_l2b3, v_l2e3, 1),
  (v_l2b4, v_l2e4, 1), (v_l2b5, v_l2e5, 1), (v_l2b6, v_l2e6, 1);

-- ── MODULE 2: Sức khỏe & Khẩn cấp ──────────────────────────────────────────
INSERT INTO public.modules (id, course_id, title, description, order_index, is_locked)
VALUES (
  v_mod2_id, v_course_id,
  'Sức khỏe & Khẩn cấp',
  'Tiếng Czech trong các tình huống quan trọng nhất: đặt lịch và gặp bác sĩ, mua thuốc tại nhà thuốc, và xử lý các trường hợp khẩn cấp. Khi sức khỏe và an toàn là ưu tiên, ngôn ngữ phải không thể sai.',
  2, false
);

-- ── LESSON 3: Tại phòng khám ────────────────────────────────────────────────
INSERT INTO public.lessons
  (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les3_id, v_mod2_id,
  'Đặt lịch và gặp bác sĩ',
  'Học cách đặt lịch khám bệnh qua điện thoại, mô tả triệu chứng, hiểu hướng dẫn của bác sĩ và tương tác tại nhà thuốc Czech.',
  25, 1, 400
);

-- L3-E1: VOCAB MCQ — bộ phận cơ thể và triệu chứng
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e1, 'mcq', 'vocabulary', 'intermediate', 10, 10, '{
  "prompt": "Bạn đến bác sĩ và cần nói ''Tôi bị đau họng và sốt cao''. Cách nói đúng bằng tiếng Czech là:\n\nA. Mám bolest zubů a horečku.\nB. Bolí mě krk a mám vysokou horečku.\nC. Mám rýmu a kašel.\nD. Bolí mě záda a jsem unavený.",
  "explanation": "''Bolí mě krk'' = cổ họng đau (throat hurts me). ''Vysoká horečka'' = sốt cao.\n\nCấu trúc quan trọng để mô tả đau:\n• Bolí mě + bộ phận = ...đau (krk=họng, hlava=đầu, břicho=bụng, záda=lưng, zuby=răng)\n• Mám horečku = tôi bị sốt\n• Mám rýmu = tôi bị chảy mũi\n• Mám kašel = tôi bị ho",
  "options": [
    {"id": "a", "text": "Mám bolest zubů a horečku.", "is_correct": false},
    {"id": "b", "text": "Bolí mě krk a mám vysokou horečku.", "is_correct": true},
    {"id": "c", "text": "Mám rýmu a kašel.", "is_correct": false},
    {"id": "d", "text": "Bolí mě záda a jsem unavený.", "is_correct": false}
  ]
}');

-- L3-E2: GRAMMAR fill_blank — đặt lịch qua điện thoại
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e2, 'fill_blank', 'grammar', 'intermediate', 10, 10, '{
  "prompt": "Điền từ thích hợp:\n\nRád ______ si objednat termín k lékaři na příští týden.\n(Tôi muốn đặt lịch khám bác sĩ vào tuần tới.)\n\nGợi ý: bych / jsem / budu",
  "correct_answer": "bych",
  "explanation": "''Rád bych...'' = Tôi muốn... (lịch sự, điều kiện)\n\nĐây là cách nói lịch sự nhất khi yêu cầu trong tiếng Czech:\n• Rád bych si objednal/a termín = Tôi muốn đặt lịch hẹn\n• Rád bych věděl/a = Tôi muốn biết\n• Chtěl/a bych = Tôi muốn (kém lịch sự hơn một chút)\n\nSo sánh: ''Chci termín'' = Tôi muốn lịch hẹn (trực tiếp, ít lịch sự)"
}');

-- L3-E3: READING MCQ — đọc tờ kê đơn thuốc
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e3, 'mcq', 'reading', 'intermediate', 10, 10, '{
  "prompt": "Đọc đơn thuốc của bác sĩ:\n\nPACIENT: Nguyen Van An, 15. 3. 1985\nDIAGNÓZA: Akutní faryngitida (J02.9)\n\nLÉKY:\n1. Amoxicilin 500 mg — 3× denně po dobu 7 dní (po jídle)\n2. Ibuprofen 400 mg — při bolesti, max. 3× denně\n3. Septofort pastilky — rozpouštět v ústech, max. 6 ks denně\n\nKontrolní návštěva: za 10 dní pokud příznaky neustoupí.\n\nBác sĩ yêu cầu bệnh nhân tái khám trong trường hợp nào?",
  "explanation": "''Kontrolní návštěva za 10 dní pokud příznaky neustoupí'' = tái khám sau 10 ngày NẾU triệu chứng không thuyên giảm. ''Akutní faryngitida'' = viêm họng cấp. ''Příznaky'' = triệu chứng. ''Neustoupit'' = không thuyên giảm.",
  "options": [
    {"id": "a", "text": "Sau 7 ngày khi hết thuốc Amoxicilin", "is_correct": false},
    {"id": "b", "text": "Sau 10 ngày nếu triệu chứng không giảm", "is_correct": true},
    {"id": "c", "text": "Ngay khi cảm thấy tốt hơn", "is_correct": false},
    {"id": "d", "text": "Chỉ khi bệnh nặng hơn", "is_correct": false}
  ]
}');

-- L3-E4: LISTENING MCQ — bác sĩ hỏi triệu chứng
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e4, 'mcq', 'listening', 'intermediate', 10, 10, '{
  "prompt": "Nghe cuộc trò chuyện tại phòng khám:\n\nBác sĩ: ''Tak co vás trápí?''\nBệnh nhân: ''Bolí mě v krku a mám horečku přes 38 stupňů. Začalo to předevčírem.''\nBác sĩ: ''Máte také kašel nebo rýmu?''\nBệnh nhân: ''Rýmu trochu, ale kašel nemám.''\nBác sĩ: ''Dobře. Podívám se vám do krku. Otevřete ústa, prosím.''\n\nBệnh nhân có những triệu chứng nào?",
  "explanation": "Từ hội thoại: ''bolí mě v krku'' = đau họng, ''horečka přes 38 stupňů'' = sốt hơn 38°C, ''rýma trochu'' = chảy mũi một chút. Không bị ho (''kašel nemám''). Bắt đầu từ ''předevčírem'' = hôm kia (2 ngày trước).",
  "options": [
    {"id": "a", "text": "Đau đầu, sốt và ho", "is_correct": false},
    {"id": "b", "text": "Đau họng, sốt và chảy mũi nhẹ", "is_correct": true},
    {"id": "c", "text": "Đau họng và ho nhiều", "is_correct": false},
    {"id": "d", "text": "Chỉ sốt cao, không có triệu chứng khác", "is_correct": false}
  ]
}');

-- L3-E5: SPEAKING — Mô tả triệu chứng với bác sĩ
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e5, 'speaking', 'speaking', 'intermediate', 20, 20, '{
  "prompt": "Tình huống: Bạn đến khám bác sĩ gia đình (praktický lékař) vì không khỏe.\n\nMô tả các triệu chứng sau bằng tiếng Czech:\n• Đau bụng dưới từ sáng hôm qua\n• Buồn nôn, không ăn được\n• Không sốt\n• Đã uống thử thuốc đau bụng nhưng không đỡ\n\nNói ít nhất 4–5 câu đầy đủ.",
  "explanation": "Câu mẫu:\n''Dobrý den, od včerejšího rána mě bolí břicho dole. Mám také nevolnost a nemůžu jíst. Horečku nemám. Vzal/a jsem si lék na bolest břicha, ale nepomohlo to.''\n\nTừ vựng:\n• bolí mě břicho dole = đau bụng dưới\n• od včerejšího rána = từ sáng hôm qua\n• nevolnost = buồn nôn\n• nemůžu jíst = không ăn được\n• horečka = sốt\n• nepomohlo to = không có tác dụng"
}');

-- L3-E6: WRITING — Viết mô tả triệu chứng cho bác sĩ
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3e6, 'writing', 'writing', 'intermediate', 20, 20, '{
  "prompt": "Viết mô tả triệu chứng bằng tiếng Czech (40–60 từ) để đưa cho bác sĩ nếu bạn không đủ tự tin nói trực tiếp.\n\nTình huống:\n• Bạn bị dị ứng với penicillin\n• Đang bị đau đầu và chóng mặt từ 3 ngày nay\n• Uống ibuprofen nhưng chỉ đỡ tạm thời\n• Bạn đang mang thai (tháng thứ 4)\n\nĐây là thông tin quan trọng bác sĩ cần biết!",
  "explanation": "Mô tả mẫu:\n''Jsem alergická na penicilin. Mám bolest hlavy a závrať už 3 dny. Brala jsem ibuprofen, pomáhalo jen dočasně. Jsem těhotná — 4. měsíc. Prosím vezměte to v úvahu při předpisu léků. Děkuji.''\n\nTừ vựng:\n• alergický/á na = dị ứng với\n• závrať = chóng mặt\n• dočasně = tạm thời\n• těhotná = mang thai\n• vezměte v úvahu = xem xét, lưu ý"
}');

-- Lesson 3 blocks
INSERT INTO public.lesson_blocks (id, lesson_id, type, order_index) VALUES
  (v_l3b1, v_les3_id, 'vocab',     1),
  (v_l3b2, v_les3_id, 'grammar',   2),
  (v_l3b3, v_les3_id, 'reading',   3),
  (v_l3b4, v_les3_id, 'listening', 4),
  (v_l3b5, v_les3_id, 'speaking',  5),
  (v_l3b6, v_les3_id, 'writing',   6);
INSERT INTO public.lesson_block_exercises (block_id, exercise_id, order_index) VALUES
  (v_l3b1, v_l3e1, 1), (v_l3b2, v_l3e2, 1), (v_l3b3, v_l3e3, 1),
  (v_l3b4, v_l3e4, 1), (v_l3b5, v_l3e5, 1), (v_l3b6, v_l3e6, 1);

-- ── LESSON 4: Tình huống khẩn cấp ───────────────────────────────────────────
INSERT INTO public.lessons
  (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les4_id, v_mod2_id,
  'Tình huống khẩn cấp',
  'Trong khẩn cấp, bạn không có thời gian tra từ điển. Bài học này giúp bạn phản xạ ngôn ngữ để gọi cấp cứu, báo cháy, trình báo mất đồ, và nhờ người lạ giúp đỡ khẩn cấp.',
  25, 2, 400
);

-- L4-E1: VOCAB MCQ — số điện thoại khẩn cấp
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e1, 'mcq', 'vocabulary', 'intermediate', 10, 10, '{
  "prompt": "Khi gọi cấp cứu (155), điều đầu tiên bạn phải nói là gì?\n\nA. Tên và địa chỉ của bạn\nB. Số chứng minh thư của nạn nhân\nC. Tên bệnh viện gần nhất\nD. Số thẻ bảo hiểm y tế",
  "explanation": "Khi gọi cấp cứu 155 tại Czech, điều quan trọng nhất là nói ngay địa chỉ (''adresa'') hoặc vị trí (''poloha'') để đội cấp cứu đến đúng nơi. Sau đó mô tả tình trạng nạn nhân.\n\nCâu mở đầu mẫu:\n''Volám z adresy Náměstí Míru 15, Praha 2. Potřebuji záchranku — muž je v bezvědomí.''\n\n• V bezvědomí = bất tỉnh\n• Nehoda = tai nạn\n• Potřebuji pomoc = cần giúp đỡ",
  "options": [
    {"id": "a", "text": "Tên và địa chỉ của bạn", "is_correct": true},
    {"id": "b", "text": "Số chứng minh thư của nạn nhân", "is_correct": false},
    {"id": "c", "text": "Tên bệnh viện gần nhất", "is_correct": false},
    {"id": "d", "text": "Số thẻ bảo hiểm y tế", "is_correct": false}
  ]
}');

-- L4-E2: GRAMMAR fill_blank — báo mất đồ với cảnh sát
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e2, 'fill_blank', 'grammar', 'intermediate', 10, 10, '{
  "prompt": "Điền dạng đúng của động từ ''ukrást'' (ăn cắp) ở thì quá khứ:\n\nNa autobuse mi ______ peněženku.\n(Trên xe buýt, tôi bị ăn cắp ví.)\n\nGợi ý: ukradli / ukradl / ukradnou",
  "correct_answer": "ukradli",
  "explanation": "''Ukradli mi peněženku'' = họ đã ăn cắp ví của tôi (thì quá khứ, ngôi 3 số nhiều ''oni'' — dùng khi không biết ai làm).\n\nCấu trúc báo mất đồ:\n• Ukradli mi... = Tôi bị ăn cắp...\n• Ztratil/a jsem... = Tôi bị mất... (do bản thân mất, không phải bị trộm)\n• Chybí mi... = Tôi thiếu mất... (không tìm thấy)\n\nKhi báo với cảnh sát: ''Chtěl/a bych nahlásit krádež.'' = Tôi muốn trình báo vụ trộm."
}');

-- L4-E3: READING MCQ — đọc hướng dẫn thoát hiểm
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e3, 'mcq', 'reading', 'intermediate', 10, 10, '{
  "prompt": "Đọc hướng dẫn thoát hiểm trong phòng khách sạn:\n\nPOKYNY PRO PŘÍPAD POŽÁRU:\n1. Při zjištění požáru stiskněte tlačítko požárního poplachu.\n2. Okamžitě opusťte pokoj a zavřete dveře za sebou.\n3. Používejte schodiště — NIKDY výtah.\n4. Sraz hostů: parkoviště před hotelem.\n5. Pokud jste uvězněni v pokoji: ucpěte mezery dveří ručníky, signalizujte z okna.\n6. Neotvírejte horké dveře.\n\nNếu bạn bị kẹt trong phòng và không thể thoát ra, bạn nên làm gì theo hướng dẫn?",
  "explanation": "Theo hướng dẫn số 5: ''ucpěte mezery dveří ručníky'' (dùng khăn bịt khe cửa để ngăn khói) và ''signalizujte z okna'' (phát tín hiệu cầu cứu từ cửa sổ). Không nên mở cửa nóng (''neotvírejte horké dveře'') vì có thể bị lửa bùng vào.",
  "options": [
    {"id": "a", "text": "Gọi thang máy để xuống", "is_correct": false},
    {"id": "b", "text": "Mở cửa để tìm đường thoát", "is_correct": false},
    {"id": "c", "text": "Dùng khăn bịt khe cửa và ra hiệu từ cửa sổ", "is_correct": true},
    {"id": "d", "text": "Chờ cứu hỏa đến mà không làm gì", "is_correct": false}
  ]
}');

-- L4-E4: LISTENING MCQ — gọi điện báo tai nạn giao thông
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e4, 'mcq', 'listening', 'intermediate', 10, 10, '{
  "prompt": "Nghe cuộc gọi cho cảnh sát (158):\n\nNgười gọi: ''Haló, volám na policii. Stala se dopravní nehoda na Evropské ulici u křižovatky s ulicí Jugoslávských partyzánů v Praze 6. Dvě auta se srazila. Jeden řidič je zraněný a nepohybuje se. Druhý je v pořádku. Já jsem svědek.''\nCảnh sát: ''Dobře, posíláme pomoc. Zůstaňte prosím na místě.''\n\nNgười gọi đang mô tả điều gì?",
  "explanation": "''Dopravní nehoda'' = tai nạn giao thông. ''Dvě auta se srazila'' = hai xe đâm nhau. ''Jeden řidič je zraněný a nepohybuje se'' = một tài xế bị thương và không cử động được. ''Svědek'' = nhân chứng. ''Zůstaňte na místě'' = ở lại hiện trường.",
  "options": [
    {"id": "a", "text": "Tai nạn giao thông với một người bị thương nặng", "is_correct": true},
    {"id": "b", "text": "Vụ trộm xe trên đường Evropská", "is_correct": false},
    {"id": "c", "text": "Hỏa hoạn tại tòa nhà ở Praha 6", "is_correct": false},
    {"id": "d", "text": "Người ngã xuống đường cần cấp cứu", "is_correct": false}
  ]
}');

-- L4-E5: SPEAKING — Gọi điện báo khẩn cấp
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e5, 'speaking', 'speaking', 'intermediate', 20, 20, '{
  "prompt": "Tình huống: Bạn đang ở công viên Stromovka, Praha 7. Bạn thấy một người cao tuổi bị ngã và không đứng dậy được. Họ tỉnh táo nhưng đau nhiều ở chân.\n\nGọi 155 (záchranná služba) và nói bằng tiếng Czech:\n• Địa điểm cụ thể (tên công viên, Praha 7)\n• Mô tả tình trạng của nạn nhân\n• Tuổi ước tính của nạn nhân\n• Số điện thoại của bạn để họ liên lạc lại\n\nNói rõ ràng và bình tĩnh — ít nhất 4–5 câu.",
  "explanation": "Câu mẫu:\n''Haló, volám ze záchranku. Jsem v parku Stromovka v Praze 7, u hlavního vchodu. Starší pán — asi 70 let — upadl a nemůže vstát. Je při vědomí, ale silně ho bolí noha. Moje číslo je 777 123 456, prosím zavolejte zpět, až budete blízko.''\n\nTừ vựng:\n• záchranná služba = cấp cứu\n• upadl/a = ngã xuống (minulý čas)\n• nemůže vstát = không đứng dậy được\n• při vědomí = còn tỉnh táo\n• bolí ho noha = chân đau"
}');

-- L4-E6: WRITING — Viết tường trình mất tài sản
INSERT INTO public.exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4e6, 'writing', 'writing', 'intermediate', 20, 20, '{
  "prompt": "Viết tường trình (50–70 từ) bằng tiếng Czech gửi cảnh sát về việc mất điện thoại.\n\nThông tin cần đưa vào:\n• Khi nào và ở đâu bạn mất điện thoại (hôm qua, 14:00–15:00, trên tàu điện ngầm Metro A)\n• Mô tả điện thoại (iPhone 14, màu đen, có ốp lưng xanh)\n• Bạn đã làm gì sau khi phát hiện mất (kiểm tra ghế ngồi, hỏi nhân viên)\n• Yêu cầu họ liên hệ nếu tìm được",
  "explanation": "Tường trình mẫu:\n''Dne včera, mezi 14:00 a 15:00, jsem ztratil/a mobilní telefon v metru linky A, pravděpodobně ve vagónu nebo na stanici Náměstí Míru. Jedná se o iPhone 14, černý, s modrým obalem. Po zjištění ztráty jsem prohledal/a sedadla a informoval/a personál metra. Prosím kontaktujte mě, pokud bude telefon nalezen. Telefon: 777 123 456.''\n\nTừ vựng:\n• ztratil/a jsem = tôi đã mất\n• jedná se o = đây là\n• obal = ốp lưng\n• po zjištění = sau khi phát hiện\n• pokud bude nalezen = nếu được tìm thấy"
}');

-- Lesson 4 blocks
INSERT INTO public.lesson_blocks (id, lesson_id, type, order_index) VALUES
  (v_l4b1, v_les4_id, 'vocab',     1),
  (v_l4b2, v_les4_id, 'grammar',   2),
  (v_l4b3, v_les4_id, 'reading',   3),
  (v_l4b4, v_les4_id, 'listening', 4),
  (v_l4b5, v_les4_id, 'speaking',  5),
  (v_l4b6, v_les4_id, 'writing',   6);
INSERT INTO public.lesson_block_exercises (block_id, exercise_id, order_index) VALUES
  (v_l4b1, v_l4e1, 1), (v_l4b2, v_l4e2, 1), (v_l4b3, v_l4e3, 1),
  (v_l4b4, v_l4e4, 1), (v_l4b5, v_l4e5, 1), (v_l4b6, v_l4e6, 1);

END $$;
