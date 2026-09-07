-- ══════════════════════════════════════════════════════════════
-- قاعدة بيانات نظام إدارة المعاهد القرآنية المغلقة (Supabase / PostgreSQL)
-- ══════════════════════════════════════════════════════════════

-- 1. إعادة تعيين الجداول
DROP TABLE IF EXISTS manager_logs CASCADE;
DROP TABLE IF EXISTS memorization_logs CASCADE;
DROP TABLE IF EXISTS general_admin_tasks CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. جدول المستخدمين (مشرف عام، مدير، مشرف)
CREATE TABLE users (
    username TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('مشرف عام', 'مدير', 'مشرف')),
    full_name TEXT NOT NULL,
    parent_username TEXT REFERENCES users(username) ON DELETE SET NULL,
    center_name TEXT DEFAULT ''
);

-- 3. جدول الطلاب
CREATE TABLE students (
    student_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    supervisor_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    manager_username TEXT REFERENCES users(username) ON DELETE SET NULL,
    supervisor_full_name TEXT,
    center_name TEXT,
    current_progress TEXT DEFAULT 'مبتدئ / قيد التحديد',
    last_update DATE DEFAULT CURRENT_DATE
);

-- 4. جدول مهام المدراء الموحدة (المشرف العام)
CREATE TABLE general_admin_tasks (
    admin_username TEXT PRIMARY KEY REFERENCES users(username) ON DELETE CASCADE,
    tasks_json JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- 5. جدول سجلات التسميع اليومية
CREATE TABLE memorization_logs (
    id BIGSERIAL PRIMARY KEY,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    student_id TEXT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    student_name TEXT NOT NULL,
    supervisor_name TEXT,
    manager_username TEXT,
    juz_number INT NOT NULL CHECK (juz_number BETWEEN 1 AND 30),
    errors_count INT DEFAULT 0,
    prompts_count INT DEFAULT 0,
    duration_minutes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. جدول تقارير المدراء
CREATE TABLE manager_logs (
    id BIGSERIAL PRIMARY KEY,
    log_date DATE NOT NULL,
    manager_username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
    manager_name TEXT NOT NULL,
    attendance_status TEXT DEFAULT 'منضبط',
    weekly_manager_tasks_summary TEXT,
    weekly_summary TEXT,
    is_sent_to_general TEXT DEFAULT 'لا',
    status TEXT DEFAULT 'نشط' CHECK (status IN ('نشط', 'مؤرشف')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_manager_log_date UNIQUE (manager_username, log_date)
);

-- 7. فهارس لتحسين سرعة القراءة والاستعلام
CREATE INDEX idx_students_supervisor ON students(supervisor_username);
CREATE INDEX idx_students_manager ON students(manager_username);
CREATE INDEX idx_mem_logs_student ON memorization_logs(student_id);
CREATE INDEX idx_mem_logs_date ON memorization_logs(log_date);
CREATE INDEX idx_mgr_logs_date ON manager_logs(log_date);

-- 8. تعطيل تقييد RLS لتمكين الوصول المباشر عبر مفتاح Anon
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE students DISABLE ROW LEVEL SECURITY;
ALTER TABLE general_admin_tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE memorization_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE manager_logs DISABLE ROW LEVEL SECURITY;

-- 9. إدخال الحسابات الافتراضية
INSERT INTO users (username, password, role, full_name, parent_username, center_name)
VALUES 
('admin', '123456', 'مشرف عام', 'د. عبدالملك المنصوري', NULL, 'الإدارة المركزية'),
('M1', '123456', 'مدير', 'أ. يوسف إبراهيم الحارثي', 'admin', 'معهد الفرقان السكني'),
('supervisor1', '123456', 'مشرف', 'أ. عمر فاروق', 'M1', 'معهد الفرقان السكني');

-- 10. إدخال مهام أولية تجريبية
INSERT INTO general_admin_tasks (admin_username, tasks_json)
VALUES ('admin', '[{"text":"هل تم الدوام 7 ساعات كاملة دون نوم؟","type":"boolean"},{"text":"كم عدد الدروس التي أقيمت خلال الأسبوع وما نوعها؟","type":"number_type"}]'::jsonb);
