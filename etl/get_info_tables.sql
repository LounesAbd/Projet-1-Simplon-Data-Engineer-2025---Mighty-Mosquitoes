-- Lister toutes les tables de la base
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- Lister les colonnes d’une table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'vehicule'
ORDER BY ordinal_position;

-- Compter le nombre de lignes dans chaque table
SELECT table_name,
       (SELECT COUNT(*) FROM public."table_name") AS row_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- Obtenir les clés primaires
SELECT kcu.table_name,
       kcu.column_name,
       tc.constraint_type
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
     ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND kcu.table_schema = 'public';

-- Obtenir les clés étrangères
SELECT tc.table_name,
       kcu.column_name,
       ccu.table_name AS foreign_table,
       ccu.column_name AS foreign_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
     ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
     ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';


