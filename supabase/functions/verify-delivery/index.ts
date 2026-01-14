// Edge Function: verify-delivery
// Vérification du code de confirmation et finalisation de la livraison
// Sécurisé côté serveur - impossible de bypass

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header manquant')
    }

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) {
      throw new Error('Utilisateur non authentifié')
    }

    const { order_id, confirmation_code } = await req.json()
    if (!order_id || !confirmation_code) {
      throw new Error('order_id et confirmation_code sont requis')
    }

    // Vérifier que l'utilisateur est un livreur vérifié
    const { data: livreur, error: livreurError } = await supabaseClient
      .from('livreurs')
      .select('id, is_verified')
      .eq('user_id', user.id)
      .single()

    if (livreurError || !livreur) {
      throw new Error('Livreur non trouvé')
    }

    if (!livreur.is_verified) {
      throw new Error('Livreur non vérifié')
    }

    // Récupérer la commande
    const { data: order, error: orderError } = await supabaseClient
      .from('orders')
      .select('id, status, confirmation_code, livreur_id, livreur_commission')
      .eq('id', order_id)
      .single()

    if (orderError || !order) {
      throw new Error('Commande non trouvée')
    }

    // Vérifier que le livreur est bien assigné à cette commande
    if (order.livreur_id !== livreur.id) {
      throw new Error('Vous n\'êtes pas assigné à cette commande')
    }

    // Vérifier le statut
    if (!['picked_up', 'delivering'].includes(order.status)) {
      throw new Error(`Statut invalide pour livraison: ${order.status}`)
    }

    // VÉRIFICATION DU CODE (CRITIQUE)
    if (order.confirmation_code !== confirmation_code.toUpperCase()) {
      // Log tentative échouée (sécurité)
      console.log(`[SECURITY] Code incorrect pour commande ${order_id} par livreur ${livreur.id}`)
      throw new Error('Code de confirmation incorrect')
    }

    // Code correct - Finaliser la livraison
    const now = new Date().toISOString()

    const { error: updateError } = await supabaseClient
      .from('orders')
      .update({
        status: 'delivered',
        delivered_at: now,
        code_verified_at: now,
      })
      .eq('id', order_id)

    if (updateError) {
      throw new Error(`Erreur finalisation: ${updateError.message}`)
    }

    // Libérer le livreur
    await supabaseClient
      .from('livreurs')
      .update({ 
        is_available: true,
        total_deliveries: supabaseClient.rpc('increment_counter', { row_id: livreur.id, table_name: 'livreurs', column_name: 'total_deliveries' })
      })
      .eq('id', livreur.id)

    // Mettre à jour les stats du livreur (simple increment)
    await supabaseClient.rpc('increment_livreur_stats', { 
      p_livreur_id: livreur.id,
      p_commission: order.livreur_commission || 0
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Livraison confirmée avec succès!',
        order_id,
        delivered_at: now,
        commission: order.livreur_commission
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
