-- ============================================================
-- Seed: Khóa học "Giao tiếp tại úřad" (Giao tiếp tại cơ quan hành chính Czech)
-- 1 course · 2 modules · 4 lessons · 24 exercises · 24 lesson_blocks
-- ============================================================

-- Ensure missing columns exist across tables
ALTER TABLE modules   ADD COLUMN IF NOT EXISTS is_locked   bool NOT NULL DEFAULT false;
ALTER TABLE courses   ADD COLUMN IF NOT EXISTS order_index int  NOT NULL DEFAULT 0;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS difficulty  text NOT NULL DEFAULT 'beginner';
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS points      int  NOT NULL DEFAULT 10;

DO $$
DECLARE
  -- IDs course / modules / lessons
  v_course_id  uuid := gen_random_uuid();
  v_mod1_id    uuid := gen_random_uuid();
  v_mod2_id    uuid := gen_random_uuid();
  v_les1_id    uuid := gen_random_uuid();
  v_les2_id    uuid := gen_random_uuid();
  v_les3_id    uuid := gen_random_uuid();
  v_les4_id    uuid := gen_random_uuid();

  -- Lesson 1 exercises (6 blocks)
  v_l1_ex1 uuid := gen_random_uuid();
  v_l1_ex2 uuid := gen_random_uuid();
  v_l1_ex3 uuid := gen_random_uuid();
  v_l1_ex4 uuid := gen_random_uuid();
  v_l1_ex5 uuid := gen_random_uuid();
  v_l1_ex6 uuid := gen_random_uuid();

  -- Lesson 2 exercises (6 blocks)
  v_l2_ex1 uuid := gen_random_uuid();
  v_l2_ex2 uuid := gen_random_uuid();
  v_l2_ex3 uuid := gen_random_uuid();
  v_l2_ex4 uuid := gen_random_uuid();
  v_l2_ex5 uuid := gen_random_uuid();
  v_l2_ex6 uuid := gen_random_uuid();

  -- Lesson 3 exercises (6 blocks)
  v_l3_ex1 uuid := gen_random_uuid();
  v_l3_ex2 uuid := gen_random_uuid();
  v_l3_ex3 uuid := gen_random_uuid();
  v_l3_ex4 uuid := gen_random_uuid();
  v_l3_ex5 uuid := gen_random_uuid();
  v_l3_ex6 uuid := gen_random_uuid();

  -- Lesson 4 exercises (6 blocks)
  v_l4_ex1 uuid := gen_random_uuid();
  v_l4_ex2 uuid := gen_random_uuid();
  v_l4_ex3 uuid := gen_random_uuid();
  v_l4_ex4 uuid := gen_random_uuid();
  v_l4_ex5 uuid := gen_random_uuid();
  v_l4_ex6 uuid := gen_random_uuid();

BEGIN

-- ═══════════════════════════════════════════════════════════════
-- COURSE
-- ═══════════════════════════════════════════════════════════════
INSERT INTO courses (id, slug, title, description, skill, is_premium, order_index,
                     instructor_name, instructor_bio, duration_days)
VALUES (
  v_course_id,
  'giao-tiep-tai-urad',
  'Giao tiếp tại úřad',
  'Học cách giao tiếp tự tin tại các cơ quan hành chính Czech — từ việc lấy số, hỏi thông tin, điền formulář đến nộp hồ sơ xin cư trú lâu dài. Khoá học tập trung vào ngôn ngữ thực tế bạn sẽ nghe và nói tại OAMP, ÚP, hay Municipal Office.',
  'speaking',
  false,
  10,
  'Mgr. Jana Horáčková',
  'Giáo viên tiếng Czech 12 năm kinh nghiệm, chuyên đào tạo người nước ngoài chuẩn bị thi Trvalý pobyt. Từng làm thông dịch viên tại Cizinecká policie Praha.',
  21
);

-- ═══════════════════════════════════════════════════════════════
-- MODULE 1: Từ vựng & cụm từ tại quầy tiếp nhận
-- ═══════════════════════════════════════════════════════════════
INSERT INTO modules (id, course_id, title, description, order_index, is_locked)
VALUES (
  v_mod1_id, v_course_id,
  'Từ vựng & cụm từ tại quầy tiếp nhận',
  'Nắm vững từ vựng cơ bản và các câu giao tiếp thiết yếu khi bạn bước vào úřad lần đầu — từ phòng chờ, bảng thông báo đến việc hỏi hướng dẫn từ nhân viên.',
  1, false
);

-- ───────────────────────────────────────────────────────────────
-- LESSON 1: Tại phòng chờ
-- ───────────────────────────────────────────────────────────────
INSERT INTO lessons (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les1_id, v_mod1_id,
  'Tại phòng chờ',
  'Bạn vừa bước vào úřad. Học cách nhận diện các khu vực, lấy số thứ tự, đọc bảng hiệu và chuẩn bị các giấy tờ cần thiết trước khi được gọi tên.',
  20, 1, 350
);

-- ── Exercises: Lesson 1 ─────────────────────────────────────────

-- L1-E1: VOCAB — MCQ từ vựng phòng chờ
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex1, 'mcq', 'vocabulary', 'beginner', 10, 10, '{
  "prompt": "''Čekárna'' có nghĩa là gì trong tiếng Việt?\n\nA. Phòng khám\nB. Phòng chờ\nC. Phòng họp\nD. Phòng vệ sinh",
  "explanation": "''Čekárna'' = phòng chờ (từ ''čekat'' = chờ đợi). Bạn sẽ thấy biển ''Čekárna'' ngay khi bước vào hầu hết các úřad ở Czech.",
  "options": [
    {"id": "a", "text": "Phòng khám", "is_correct": false},
    {"id": "b", "text": "Phòng chờ", "is_correct": true},
    {"id": "c", "text": "Phòng họp", "is_correct": false},
    {"id": "d", "text": "Phòng vệ sinh", "is_correct": false}
  ]
}');

-- L1-E2: GRAMMAR — Fill-blank đặt câu xin số thứ tự
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex2, 'fill_blank', 'grammar', 'beginner', 10, 10, '{
  "prompt": "Điền từ thích hợp vào chỗ trống:\n\nProsím, kde si ______ číslo?\n(Xin hỏi, tôi lấy số ở đâu?)\n\nGợi ý: vezmu / dám / najdu",
  "correct_answer": "vezmu",
  "explanation": "''Kde si vezmu číslo?'' = Tôi lấy số ở đâu? Động từ ''vzít si'' (lấy cho mình) chia ngôi thứ nhất số ít: ''vezmu si''. Trong khẩu ngữ nói nhanh, ''si'' thường được lược bỏ."
}');

-- L1-E3: READING — MCQ đọc biển thông báo
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex3, 'mcq', 'reading', 'beginner', 10, 10, '{
  "prompt": "Đọc biển thông báo tại cửa:\n\n┌─────────────────────────────┐\n│  ODDĚLENÍ POBYTU CIZINCŮ    │\n│  Úřední hodiny:             │\n│  Po, St: 8:00 – 17:00       │\n│  Út, Čt: 8:00 – 12:00       │\n│  Pá: ZAVŘENO                │\n└─────────────────────────────┘\n\nBạn đến vào thứ Sáu lúc 10 giờ sáng. Cơ quan có mở cửa không?",
  "explanation": "''Pá'' = Pátek = thứ Sáu. ''ZAVŘENO'' = đóng cửa. Vậy thứ Sáu cơ quan này đóng cửa. ''Oddělení pobytu cizinců'' = Phòng cư trú người nước ngoài — đây là phòng bạn cần đến khi xin Trvalý pobyt.",
  "options": [
    {"id": "a", "text": "Có, mở cửa từ 8:00 đến 12:00", "is_correct": false},
    {"id": "b", "text": "Có, mở cửa từ 8:00 đến 17:00", "is_correct": false},
    {"id": "c", "text": "Không, thứ Sáu đóng cửa", "is_correct": true},
    {"id": "d", "text": "Không đủ thông tin để trả lời", "is_correct": false}
  ]
}');

-- L1-E4: LISTENING — MCQ nghe số thứ tự được gọi
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex4, 'mcq', 'listening', 'beginner', 10, 10, '{
  "prompt": "Bạn nghe thông báo trên loa:\n\n''Číslo čtyřicet sedm, prosím přijďte k okénku číslo tři.''\n\nSố thứ tự nào được gọi và đến quầy nào?",
  "explanation": "''Čtyřicet sedm'' = 47. ''Okénko číslo tři'' = quầy số 3. Trong thực tế, hệ thống điện tử tại úřad thường đọc số bằng tiếng Czech — hãy tập đếm số từ 1 đến 100 để không bỏ lỡ lượt của mình!",
  "options": [
    {"id": "a", "text": "Số 37, quầy số 3", "is_correct": false},
    {"id": "b", "text": "Số 47, quầy số 3", "is_correct": true},
    {"id": "c", "text": "Số 47, quầy số 7", "is_correct": false},
    {"id": "d", "text": "Số 74, quầy số 3", "is_correct": false}
  ]
}');

-- L1-E5: SPEAKING — Tự giới thiệu tại quầy
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex5, 'speaking', 'speaking', 'beginner', 20, 20, '{
  "prompt": "Nhân viên tại quầy nói: ''Dobrý den, čím vám mohu pomoci?''\n(Xin chào, tôi có thể giúp gì cho bạn?)\n\nHãy trả lời bằng tiếng Czech:\n• Chào hỏi lại\n• Cho biết họ tên đầy đủ của bạn\n• Nói bạn đến để nộp hồ sơ xin Trvalý pobyt\n\nNói ít nhất 2–3 câu.",
  "explanation": "Câu trả lời mẫu:\n''Dobrý den. Jmenuji se Nguyen Van An. Přišel jsem podat žádost o trvalý pobyt.''\n\nTừ vựng quan trọng:\n• jmenuji se = tôi tên là\n• přišel/přišla jsem = tôi đến (nam/nữ)\n• podat žádost = nộp đơn\n• trvalý pobyt = cư trú lâu dài"
}');

-- L1-E6: WRITING — Viết yêu cầu đơn giản
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l1_ex6, 'writing', 'writing', 'beginner', 20, 20, '{
  "prompt": "Viết một ghi chú ngắn (30–50 từ) bằng tiếng Czech gửi cho nhân viên úřad:\n\nBạn cần hẹn lịch gặp để nộp hồ sơ Trvalý pobyt. Ghi rõ:\n• Tên đầy đủ của bạn\n• Số điện thoại liên hệ\n• Thời gian bạn có thể đến (buổi sáng, thứ 2 đến thứ 4)",
  "explanation": "Ghi chú mẫu:\n''Dobrý den,\nrád/ráda bych si domluvil/a schůzku ohledně podání žádosti o trvalý pobyt. Jmenuji se Nguyen Van An, telefon: 777 123 456. Mohu přijít v pondělí až středu dopoledne.\nDěkuji.''\n\nTừ vựng:\n• domluvit si schůzku = đặt lịch hẹn\n• ohledně = liên quan đến\n• dopoledne = buổi sáng"
}');

-- ── Lesson 1 blocks ───────────────────────────────────────────
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
  (gen_random_uuid(), v_les1_id, 'vocab',     v_l1_ex1, 1),
  (gen_random_uuid(), v_les1_id, 'grammar',   v_l1_ex2, 2),
  (gen_random_uuid(), v_les1_id, 'reading',   v_l1_ex3, 3),
  (gen_random_uuid(), v_les1_id, 'listening', v_l1_ex4, 4),
  (gen_random_uuid(), v_les1_id, 'speaking',  v_l1_ex5, 5),
  (gen_random_uuid(), v_les1_id, 'writing',   v_l1_ex6, 6);

-- ───────────────────────────────────────────────────────────────
-- LESSON 2: Hỏi thông tin & xin giúp đỡ
-- ───────────────────────────────────────────────────────────────
INSERT INTO lessons (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les2_id, v_mod1_id,
  'Hỏi thông tin & xin giúp đỡ',
  'Học cách hỏi hướng dẫn, xin nhân viên giải thích quy trình và sử dụng modal verbs thể hiện sự lịch sự — những kỹ năng quan trọng để vượt qua rào cản ngôn ngữ tại úřad.',
  20, 2, 350
);

-- L2-E1: VOCAB — MCQ từ vựng hỏi đường trong úřad
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex1, 'mcq', 'vocabulary', 'beginner', 10, 10, '{
  "prompt": "Bạn cần tìm phòng nộp hồ sơ. Cụm từ nào đúng để hỏi nhân viên bảo vệ?\n\nA. Kde je záchod?\nB. Kde je podatelna?\nC. Kde je jídelna?\nD. Kde je parkoviště?",
  "explanation": "''Podatelna'' = phòng tiếp nhận hồ sơ / văn phòng tiếp nhận. Đây là từ bạn cần biết khi nộp bất kỳ giấy tờ nào tại cơ quan Czech.\n\n• záchod = nhà vệ sinh\n• jídelna = căng tin\n• parkoviště = bãi đỗ xe",
  "options": [
    {"id": "a", "text": "Kde je záchod?", "is_correct": false},
    {"id": "b", "text": "Kde je podatelna?", "is_correct": true},
    {"id": "c", "text": "Kde je jídelna?", "is_correct": false},
    {"id": "d", "text": "Kde je parkoviště?", "is_correct": false}
  ]
}');

-- L2-E2: GRAMMAR — Fill-blank modal verbs lịch sự
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex2, 'fill_blank', 'grammar', 'beginner', 10, 10, '{
  "prompt": "Điền modal verb thích hợp:\n\n______ bych vám něco říct?\n(Tôi có thể nói với bạn điều gì đó không?)\n\nGợi ý: Mohl / Musel / Měl",
  "correct_answer": "Mohl",
  "explanation": "''Mohl bych'' (nam) / ''Mohla bych'' (nữ) = Tôi có thể... không? — cách nói lịch sự nhất trong tiếng Czech khi hỏi xin phép.\n\n• Mohl/Mohla bych = Could I (lịch sự)\n• Mohu = I can/may (trung tính)\n• Musel/Musela = I must (bắt buộc)\n• Měl/Měla bych = I should"
}');

-- L2-E3: READING — MCQ đọc hướng dẫn bảng thông báo
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex3, 'mcq', 'reading', 'beginner', 10, 10, '{
  "prompt": "Đọc hướng dẫn trên bảng:\n\n''Pro podání žádosti o trvalý pobyt je nutné:\n1. Vyplněný formulář OAM\n2. Platný cestovní pas\n3. Doklad o ubytování\n4. Doklad o příjmu za poslední 2 roky\n5. 2 fotografie (3,5 × 4,5 cm)''\n\nTheo hướng dẫn, bạn cần bao nhiêu tấm ảnh?",
  "explanation": "''Dvě fotografie'' = 2 tấm ảnh, kích thước 3,5 × 4,5 cm — đây là kích thước ảnh hộ chiếu tiêu chuẩn tại Czech. Hãy chuẩn bị ảnh trước khi đến úřad để tiết kiệm thời gian.",
  "options": [
    {"id": "a", "text": "1 tấm", "is_correct": false},
    {"id": "b", "text": "2 tấm", "is_correct": true},
    {"id": "c", "text": "3 tấm", "is_correct": false},
    {"id": "d", "text": "Không cần ảnh", "is_correct": false}
  ]
}');

-- L2-E4: LISTENING — MCQ nghe nhân viên giải thích
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex4, 'mcq', 'listening', 'beginner', 10, 10, '{
  "prompt": "Nhân viên nói:\n\n''Váš formulář je vyplněný správně, ale chybí vám doklad o ubytování. Musíte ho donést do 30 dnů, jinak vaše žádost bude zamítnuta.''\n\nNhân viên yêu cầu bạn làm gì?",
  "explanation": "''Doklad o ubytování'' = giấy chứng nhận nơi ở (ví dụ: hợp đồng thuê nhà). ''Zamítnuta'' = bị từ chối. Bạn có 30 ngày (''30 dnů'') để bổ sung giấy tờ còn thiếu.",
  "options": [
    {"id": "a", "text": "Điền lại formulář vì sai", "is_correct": false},
    {"id": "b", "text": "Nộp thêm doklad o ubytování trong 30 ngày", "is_correct": true},
    {"id": "c", "text": "Quay lại vào ngày mai", "is_correct": false},
    {"id": "d", "text": "Đóng thêm lệ phí", "is_correct": false}
  ]
}');

-- L2-E5: SPEAKING — Xin giúp đỡ và hỏi thủ tục
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex5, 'speaking', 'speaking', 'beginner', 20, 20, '{
  "prompt": "Bạn không hiểu quy trình và cần nhân viên giải thích lại chậm hơn.\n\nHãy nói bằng tiếng Czech:\n• Xin lỗi, bạn không hiểu\n• Nhờ nhân viên nói chậm hơn\n• Hỏi xem bạn cần mang giấy tờ gì\n\nNói ít nhất 3 câu.",
  "explanation": "Câu trả lời mẫu:\n''Promiňte, nerozumím. Mohl/Mohla byste mluvit pomaleji? Jaké dokumenty potřebuji přinést?''\n\nTừ vựng quan trọng:\n• Promiňte = xin lỗi (lịch sự)\n• Nerozumím = tôi không hiểu\n• Mluvit pomaleji = nói chậm hơn\n• Jaké dokumenty = giấy tờ gì"
}');

-- L2-E6: WRITING — Viết câu hỏi bằng văn bản
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l2_ex6, 'writing', 'writing', 'beginner', 20, 20, '{
  "prompt": "Viết email ngắn (40–60 từ) gửi úřad bằng tiếng Czech để hỏi:\n• Bạn cần những giấy tờ gì để xin Trvalý pobyt?\n• Thời gian xử lý hồ sơ mất bao lâu?\n• Có thể đặt lịch hẹn trực tuyến không?",
  "explanation": "Email mẫu:\n''Dobrý den,\nrád/ráda bych se zeptal/a, jaké dokumenty jsou potřeba pro žádost o trvalý pobyt a jak dlouho trvá vyřízení. Je možné si objednat termín online?\nDěkuji za odpověď.\nS pozdravem, Nguyen Van An''\n\nTừ vựng:\n• zeptat se = hỏi\n• jak dlouho trvá = mất bao lâu\n• vyřízení = xử lý\n• objednat termín = đặt lịch hẹn"
}');

-- ── Lesson 2 blocks ───────────────────────────────────────────
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
  (gen_random_uuid(), v_les2_id, 'vocab',     v_l2_ex1, 1),
  (gen_random_uuid(), v_les2_id, 'grammar',   v_l2_ex2, 2),
  (gen_random_uuid(), v_les2_id, 'reading',   v_l2_ex3, 3),
  (gen_random_uuid(), v_les2_id, 'listening', v_l2_ex4, 4),
  (gen_random_uuid(), v_les2_id, 'speaking',  v_l2_ex5, 5),
  (gen_random_uuid(), v_les2_id, 'writing',   v_l2_ex6, 6);

-- ═══════════════════════════════════════════════════════════════
-- MODULE 2: Điền form & nộp hồ sơ
-- ═══════════════════════════════════════════════════════════════
INSERT INTO modules (id, course_id, title, description, order_index, is_locked)
VALUES (
  v_mod2_id, v_course_id,
  'Điền form & nộp hồ sơ',
  'Thực hành đọc và điền các mẫu đơn chính thức của Czech, hiểu từng trường thông tin cần thiết, và xử lý các tình huống bất ngờ khi nộp hồ sơ như thiếu giấy tờ hoặc cần bổ sung thông tin.',
  2, false
);

-- ───────────────────────────────────────────────────────────────
-- LESSON 3: Đọc và điền formulář
-- ───────────────────────────────────────────────────────────────
INSERT INTO lessons (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les3_id, v_mod2_id,
  'Đọc và điền formulář',
  'Formulář OAM — mẫu đơn xin cư trú — có nhiều trường thông tin với từ ngữ pháp lý phức tạp. Bài này giúp bạn hiểu từng mục, tránh điền sai và bị trả lại hồ sơ.',
  25, 1, 400
);

-- L3-E1: VOCAB — MCQ từ vựng điền form
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex1, 'mcq', 'vocabulary', 'intermediate', 10, 10, '{
  "prompt": "Trong formulář, trường ''Rodné číslo'' yêu cầu bạn điền gì?\n\nA. Số hộ chiếu\nB. Mã số cá nhân Czech (tương tự số CMND)\nC. Ngày sinh\nD. Nơi sinh",
  "explanation": "''Rodné číslo'' = mã số cá nhân Czech (personal identification number). Người nước ngoài sẽ có mã này sau khi đăng ký cư trú lần đầu. Định dạng: NNMMDD/XXXX (ví dụ: 850315/1234). Nếu chưa có, ghi ''nemám'' hoặc để trống và hỏi nhân viên.",
  "options": [
    {"id": "a", "text": "Số hộ chiếu", "is_correct": false},
    {"id": "b", "text": "Mã số cá nhân Czech", "is_correct": true},
    {"id": "c", "text": "Ngày sinh", "is_correct": false},
    {"id": "d", "text": "Nơi sinh", "is_correct": false}
  ]
}');

-- L3-E2: GRAMMAR — Fill-blank genitive địa chỉ
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex2, 'fill_blank', 'grammar', 'intermediate', 10, 10, '{
  "prompt": "Điền dạng đúng của địa chỉ trong câu:\n\nBydlím na ulici ______. (Nguyen Thi Lan sống ở phố Mánesova)\n\nĐiền: Mánesova (cách 2 - genitive) hay Mánesova (cách 1)?",
  "correct_answer": "Mánesova",
  "explanation": "Sau ''na ulici'' (ở phố), danh từ đường phố chia theo cách 6 (lokál): ''na ulici Mánesově''. Tuy nhiên trong ngôn ngữ thực tế và trên formulář, người ta thường dùng nguyên dạng tên phố mà không biến đổi. Hãy viết đúng tên phố theo giấy tờ nhà."
}');

-- L3-E3: READING — MCQ tìm lỗi trong formulář
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex3, 'mcq', 'reading', 'intermediate', 10, 10, '{
  "prompt": "Đọc đoạn điền trên formulář và tìm lỗi sai:\n\nJméno: NGUYEN\nPříjmení: VAN AN\nDatum narození: 15.3.1985\nMísto narození: Ho Chi Minh\nStátní příslušnost: vietnamská\nTrvalé bydliště v ČR: Mánesova 15, Praha 2, 120 00\n\nLỗi nào cần sửa?",
  "explanation": "''Jméno'' = tên (first name) và ''Příjmení'' = họ (last name/surname). Trong ví dụ này, họ ''NGUYEN'' được điền vào Jméno (tên), còn ''VAN AN'' điền vào Příjmení (họ) — đây là lỗi ngược. Cần đổi lại: Jméno = VAN AN, Příjmení = NGUYEN.",
  "options": [
    {"id": "a", "text": "Ngày sinh ghi sai định dạng", "is_correct": false},
    {"id": "b", "text": "Họ và tên bị điền ngược (Jméno ↔ Příjmení)", "is_correct": true},
    {"id": "c", "text": "Thiếu mã bưu điện", "is_correct": false},
    {"id": "d", "text": "Tên quốc tịch viết sai", "is_correct": false}
  ]
}');

-- L3-E4: LISTENING — MCQ nghe nhân viên giải thích field
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex4, 'mcq', 'listening', 'intermediate', 10, 10, '{
  "prompt": "Nhân viên giải thích:\n\n''Do pole ''Účel pobytu'' napište ''za účelem sloučení rodiny'' nebo ''za účelem zaměstnání'', podle toho, proč žádáte o pobyt.''\n\nNhân viên đang giải thích trường nào trong formulář?",
  "explanation": "''Účel pobytu'' = mục đích cư trú. Đây là một trong những trường quan trọng nhất trong đơn Trvalý pobyt. Các giá trị thông thường:\n• Za účelem sloučení rodiny = đoàn tụ gia đình\n• Za účelem zaměstnání = mục đích công việc\n• Za účelem studia = mục đích học tập",
  "options": [
    {"id": "a", "text": "Trường ngày đến Czech", "is_correct": false},
    {"id": "b", "text": "Trường mục đích cư trú", "is_correct": true},
    {"id": "c", "text": "Trường nơi làm việc", "is_correct": false},
    {"id": "d", "text": "Trường trình độ học vấn", "is_correct": false}
  ]
}');

-- L3-E5: SPEAKING — Đọc to thông tin cá nhân
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex5, 'speaking', 'speaking', 'intermediate', 20, 20, '{
  "prompt": "Nhân viên yêu cầu bạn xác nhận lại thông tin cá nhân bằng miệng.\n\nHãy đọc to bằng tiếng Czech các thông tin sau:\n• Họ tên đầy đủ của bạn\n• Ngày sinh (dùng định dạng Czech: DD. MM. YYYY)\n• Địa chỉ hiện tại tại Czech\n• Quốc tịch\n\nSử dụng câu đầy đủ, ít nhất 4 câu.",
  "explanation": "Câu mẫu:\n''Jmenuji se Nguyen Van An. Narodil/Narodila jsem se patnáctého třetího, devatenáct set osmdesát pět. Bydlím na Mánesově ulici číslo patnáct v Praze dva. Jsem vietnamské státní příslušnosti.''\n\nLưu ý: Ngày trong tiếng Czech dùng thứ tự (ordinal): patnáctého = thứ 15 (cách 2)."
}');

-- L3-E6: WRITING — Viết địa chỉ Czech
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l3_ex6, 'writing', 'writing', 'intermediate', 20, 20, '{
  "prompt": "Viết địa chỉ đầy đủ của bạn theo chuẩn Czech (30–50 từ), bao gồm:\n\n1. Tên đường và số nhà\n2. Tên quận/thành phố\n3. Mã bưu điện (PSČ)\n4. Tên quốc gia (nếu không phải Czech)\n\nVí dụ địa chỉ mẫu để bạn tập viết theo cấu trúc:\nNguyễn Văn An, Mánesova 15/8, Praha 2, 120 00, Česká republika",
  "explanation": "Cấu trúc địa chỉ Czech:\n[Tên đường] [Số nhà/Số căn hộ]\n[Mã bưu điện] [Tên thành phố]\n[Quốc gia]\n\nSố nhà ở Czech thường có 2 số: số đường (orientační číslo) sau dấu ''/''. Ví dụ: Mánesova 15/8 = số nhà 15, căn hộ 8.\n\nMã bưu điện (PSČ) luôn 5 chữ số, Praha 2 = 120 00."
}');

-- ── Lesson 3 blocks ───────────────────────────────────────────
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
  (gen_random_uuid(), v_les3_id, 'vocab',     v_l3_ex1, 1),
  (gen_random_uuid(), v_les3_id, 'grammar',   v_l3_ex2, 2),
  (gen_random_uuid(), v_les3_id, 'reading',   v_l3_ex3, 3),
  (gen_random_uuid(), v_les3_id, 'listening', v_l3_ex4, 4),
  (gen_random_uuid(), v_les3_id, 'speaking',  v_l3_ex5, 5),
  (gen_random_uuid(), v_les3_id, 'writing',   v_l3_ex6, 6);

-- ───────────────────────────────────────────────────────────────
-- LESSON 4: Nộp hồ sơ & xử lý tình huống
-- ───────────────────────────────────────────────────────────────
INSERT INTO lessons (id, module_id, title, description, duration_minutes, order_index, bonus_xp_cost)
VALUES (
  v_les4_id, v_mod2_id,
  'Nộp hồ sơ & xử lý tình huống',
  'Ngày nộp hồ sơ có thể xảy ra nhiều tình huống bất ngờ: thiếu giấy tờ, yêu cầu công chứng, hay cần bổ sung thông tin. Bài này trang bị cho bạn ngôn ngữ để xử lý tự tin.',
  25, 2, 400
);

-- L4-E1: VOCAB — MCQ từ vựng hồ sơ/tài liệu
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex1, 'mcq', 'vocabulary', 'intermediate', 10, 10, '{
  "prompt": "Nhân viên nói: ''Potřebuji ověřenou kopii vašeho pasu.''\n\n''Ověřená kopie'' có nghĩa là gì?\n\nA. Bản sao thường (photocopy)\nB. Bản sao có công chứng/xác thực\nC. Bản gốc\nD. Bản dịch có chứng thực",
  "explanation": "''Ověřená kopie'' = bản sao có xác thực (certified copy). Khác với ''prostá kopie'' (bản photocopy thường).\n\nĐể có ověřená kopie tại Czech, bạn đến Czech Point (tại bưu điện, úřad) hoặc notář (công chứng viên). Lệ phí khoảng 30–100 Kč mỗi tờ.",
  "options": [
    {"id": "a", "text": "Bản sao thường (photocopy)", "is_correct": false},
    {"id": "b", "text": "Bản sao có công chứng/xác thực", "is_correct": true},
    {"id": "c", "text": "Bản gốc", "is_correct": false},
    {"id": "d", "text": "Bản dịch có chứng thực", "is_correct": false}
  ]
}');

-- L4-E2: GRAMMAR — Fill-blank conditional tình huống bất ngờ
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex2, 'fill_blank', 'grammar', 'intermediate', 10, 10, '{
  "prompt": "Điền dạng đúng:\n\nKdybych ______ pas, přinesl bych ho zítra.\n(Nếu tôi có hộ chiếu, tôi sẽ mang nó đến vào ngày mai.)\n\nGợi ý: měl / mám / budu mít",
  "correct_answer": "měl",
  "explanation": "Câu điều kiện (conditional) loại 2 trong tiếng Czech:\n''Kdybych + quá khứ phân từ..., + điều kiện...''\n\n• měl (nam) / měla (nữ) = had (had something)\n• Kdybych měl = If I had\n\nĐây là cấu trúc thường dùng khi giải thích tình huống thiếu giấy tờ tại úřad."
}');

-- L4-E3: READING — MCQ đọc email thông báo từ úřad
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex3, 'mcq', 'reading', 'intermediate', 10, 10, '{
  "prompt": "Đọc email từ úřad:\n\n''Vážený pane Nguyen,\ndovolujeme si Vás informovat, že Vaše žádost o trvalý pobyt č. 2024/15847 byla přijata k řízení dne 15. dubna 2024. Lhůta pro vydání rozhodnutí je 60 dnů od tohoto data. V případě potřeby dalších podkladů Vás budeme kontaktovat.\nS pozdravem,\nOddělení pobytu cizinců''\n\nTheo email, khi nào úřad phải ra quyết định chậm nhất?",
  "explanation": "''Lhůta pro vydání rozhodnutí je 60 dnů'' = thời hạn ban hành quyết định là 60 ngày. Tính từ 15/4/2024, thời hạn là 14/6/2024.\n\nTừ vựng quan trošku:\n• žádost byla přijata k řízení = đơn được tiếp nhận xử lý\n• lhůta = thời hạn\n• vydání rozhodnutí = ban hành quyết định\n• podklady = hồ sơ, tài liệu bổ sung",
  "options": [
    {"id": "a", "text": "Sau 30 ngày kể từ 15/4/2024", "is_correct": false},
    {"id": "b", "text": "Sau 60 ngày kể từ 15/4/2024", "is_correct": true},
    {"id": "c", "text": "Sau 90 ngày kể từ 15/4/2024", "is_correct": false},
    {"id": "d", "text": "Email không nêu thời hạn", "is_correct": false}
  ]
}');

-- L4-E4: LISTENING — MCQ nghe hội thoại nộp hồ sơ
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex4, 'mcq', 'listening', 'intermediate', 10, 10, '{
  "prompt": "Nghe đoạn hội thoại tại quầy:\n\nNhân viên: ''Bohužel, váš doklad o příjmu je starší než 90 dní. Potřebujeme aktuální potvrzení od zaměstnavatele.''\nBạn: ''Jak dlouho bude trvat, než ho dostanu?''\nNhân viên: ''Obvykle jeden až dva pracovní dny. Pak ho přineste sem a my vaše řízení obnovíme.''\n\nBạn cần làm gì tiếp theo?",
  "explanation": "Nhân viên yêu cầu ''aktuální potvrzení od zaměstnavatele'' = xác nhận thu nhập mới từ công ty (không được cũ hơn 90 ngày). Bạn cần xin cty cấp giấy xác nhận mới (thường mất 1-2 ngày làm việc), rồi quay lại úřad nộp bổ sung.",
  "options": [
    {"id": "a", "text": "Nộp lại toàn bộ hồ sơ từ đầu", "is_correct": false},
    {"id": "b", "text": "Xin giấy xác nhận thu nhập mới từ công ty rồi quay lại", "is_correct": true},
    {"id": "c", "text": "Đợi 90 ngày rồi quay lại", "is_correct": false},
    {"id": "d", "text": "Yêu cầu gặp trưởng phòng", "is_correct": false}
  ]
}');

-- L4-E5: SPEAKING — Giải thích thiếu giấy tờ
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex5, 'speaking', 'speaking', 'intermediate', 20, 20, '{
  "prompt": "Tình huống: Bạn quên mang bản sao hộ chiếu. Nhân viên nói ''Potřebuji kopii vašeho pasu.''\n\nHãy giải thích tình huống bằng tiếng Czech:\n• Xin lỗi vì quên mang giấy tờ\n• Giải thích bạn có thể mang đến khi nào\n• Hỏi xem có thể email/gửi online không\n\nNói ít nhất 3–4 câu.",
  "explanation": "Câu mẫu:\n''Promiňte, zapomněl/zapomněla jsem kopii pasu. Mohu ji přinést zítra dopoledne. Je možné ji zaslat emailem, nebo musím přijít osobně? Moc se omlouvám za komplikace.''\n\nTừ vựng:\n• zapomenout = quên\n• zaslat emailem = gửi qua email\n• přijít osobně = đến trực tiếp\n• omlouvat se = xin lỗi"
}');

-- L4-E6: WRITING — Viết email xin hẹn lại
INSERT INTO exercises (id, type, skill, difficulty, points, xp_reward, content_json)
VALUES (v_l4_ex6, 'writing', 'writing', 'intermediate', 20, 20, '{
  "prompt": "Viết email (50–70 từ) gửi úřad bằng tiếng Czech để:\n• Giải thích bạn cần thay đổi lịch hẹn đã đặt (ngày 20/5 lúc 10:00)\n• Đề xuất 2 thời điểm thay thế\n• Xin lỗi vì sự bất tiện\n\nGhi rõ số hồ sơ: 2024/15847",
  "explanation": "Email mẫu:\n''Dobrý den,\nrád/ráda bych přeložil/přeložila termín schůzky č. 2024/15847, plánovaný na 20. 5. v 10:00 hodin. Navrhuji náhradní termín 22. 5. nebo 23. 5. dopoledne.\nOmlouvám se za případné komplikace.\nS pozdravem, Nguyen Van An''\n\nTừ vựng:\n• přeložit termín = dời lịch hẹn\n• navrhnout = đề xuất\n• náhradní termín = lịch thay thế"
}');

-- ── Lesson 4 blocks ───────────────────────────────────────────
INSERT INTO lesson_blocks (id, lesson_id, type, exercise_id, order_index) VALUES
  (gen_random_uuid(), v_les4_id, 'vocab',     v_l4_ex1, 1),
  (gen_random_uuid(), v_les4_id, 'grammar',   v_l4_ex2, 2),
  (gen_random_uuid(), v_les4_id, 'reading',   v_l4_ex3, 3),
  (gen_random_uuid(), v_les4_id, 'listening', v_l4_ex4, 4),
  (gen_random_uuid(), v_les4_id, 'speaking',  v_l4_ex5, 5),
  (gen_random_uuid(), v_les4_id, 'writing',   v_l4_ex6, 6);

END $$;
