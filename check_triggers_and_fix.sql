-- Vérifier les triggers existants sur la table orders
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE event_object_table = 'orders';

-- Vérifier les fonctions qui mentionnent 'transactions'
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_definition LIKE '%transactions%'
  AND routine_schema = 'public';
