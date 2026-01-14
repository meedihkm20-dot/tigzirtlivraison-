-- Vérifier le schéma de la table restaurants
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'restaurants'
ORDER BY ordinal_position;

-- Vérifier les données du restaurant test
SELECT * FROM restaurants WHERE name LIKE '%Test%';
