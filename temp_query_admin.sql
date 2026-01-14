-- Trouver l'email de l'admin
SELECT 
    u.email,
    p.role,
    p.full_name,
    p.phone,
    u.created_at
FROM auth.users u
JOIN profiles p ON p.id = u.id
WHERE p.role = 'admin'
LIMIT 10;
