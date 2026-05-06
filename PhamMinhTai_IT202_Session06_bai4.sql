-- =========================================================
-- AIO: BÁO CÁO "KHÁCH SẠN ĐẠT CHUẨN"
-- =========================================================

-- Bảng giả định:
-- bookings(booking_id, hotel_id, status, total_price, created_at)

-- =========================================================
-- 1. BAD PRACTICE (LỌC TRỄ - DÙNG HAVING)
-- =========================================================

--  Ý tưởng:
-- - Gom toàn bộ dữ liệu (kể cả FAILED, CANCELLED)
-- - Sau đó mới lọc bằng HAVING

SELECT 
    hotel_id,
    COUNT(*) AS total_completed,
    AVG(total_price) AS avg_revenue
FROM bookings
GROUP BY hotel_id
HAVING 
    SUM(CASE 
            WHEN status = 'COMPLETED' THEN 1 
            ELSE 0 
        END) >= 50
    AND 
    AVG(CASE 
            WHEN status = 'COMPLETED' THEN total_price 
        END) > 3000000;

--  Nhược điểm:
-- - Scan toàn bộ bảng
-- - GROUP BY trên dữ liệu không cần thiết
-- - Tốn CPU + RAM + I/O

-- =========================================================
-- 2. BEST PRACTICE (LỌC SỚM - WHERE + HAVING)
-- =========================================================

--  Ý tưởng:
-- - WHERE lọc trước (chỉ giữ COMPLETED)
-- - GROUP BY sau
-- - HAVING lọc theo aggregate

SELECT 
    hotel_id,
    COUNT(*) AS total_completed,
    AVG(total_price) AS avg_revenue
FROM bookings
WHERE status = 'COMPLETED'          -- lọc sớm
GROUP BY hotel_id
HAVING 
    COUNT(*) >= 50                  -- số đơn >= 50
    AND 
    AVG(total_price) > 3000000;     -- doanh thu TB > 3tr

-- =========================================================
-- 3. VERSION TỐI GIẢN (THEO ĐỀ BÀI)
-- =========================================================

-- Chỉ cần output hotel_id

SELECT 
    hotel_id
FROM bookings
WHERE status = 'COMPLETED'
GROUP BY hotel_id
HAVING 
    COUNT(*) >= 50
    AND AVG(total_price) > 3000000;

-- =========================================================
-- 4. EXECUTION ORDER (NHỚ THUỘC)
-- =========================================================
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

-- =========================================================
-- 5. PERFORMANCE INSIGHT
-- =========================================================

--  HAVING-only:
-- - xử lý toàn bộ dữ liệu
-- - group dư thừa
-- - tốn RAM + CPU

--  WHERE + HAVING:
-- - giảm data trước khi group
-- - tận dụng index
-- - nhanh hơn rất nhiều

-- =========================================================
-- 6. INDEX GỢI Ý (THỰC TẾ)
-- =========================================================

-- Tối ưu filter + group
CREATE INDEX idx_booking_status_hotel 
ON bookings(status, hotel_id);

-- =========================================================
-- 7. BONUS (LEVEL CAO)
-- =========================================================

-- Thêm doanh thu tổng + sắp xếp
SELECT 
    hotel_id,
    COUNT(*) AS total_completed,
    AVG(total_price) AS avg_revenue,
    SUM(total_price) AS total_revenue
FROM bookings
WHERE status = 'COMPLETED'
GROUP BY hotel_id
HAVING 
    COUNT(*) >= 50
    AND AVG(total_price) > 3000000
ORDER BY total_revenue DESC;

-- =========================================================
-- 8. KẾT LUẬN
-- =========================================================
--  WHERE  : lọc sớm (giảm data)
--  HAVING : lọc sau GROUP
--  Tối ưu = giảm dữ liệu trước khi tính toán
--  Pattern này = cực kỳ quan trọng (thi + thực tế)
-- =========================================================