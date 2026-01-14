-- ============================================
-- ACTIVER LES EXTENSIONS NÉCESSAIRES
-- ============================================

-- 1. uuid-ossp (pour gen_random_uuid())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. pgcrypto (pour crypt() et gen_salt())
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 3. postgis (pour calculs de distance géographique)
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 4. Vérifier que tout est activé
SELECT 
    '✅ Extensions activées' as status,
    extname,
    extversion
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'pgcrypto', 'postgis')
ORDER BY extname;

-- 5. Tester uuid-ossp
SELECT 
    '✅ Test uuid-ossp' as test,
    uuid_generate_v4() as sample_uuid;

-- 6. Tester pgcrypto
SELECT 
    '✅ Test pgcrypto' as test,
    crypt('test', gen_salt('bf')) as sample_hash;

-- 7. Tester postgis (calcul distance)
SELECT 
    '✅ Test postgis' as test,
    ST_Distance(
        ST_MakePoint(4.1260, 36.8869)::geography,
        ST_MakePoint(4.1300, 36.8900)::geography
    ) / 1000 as distance_km;
