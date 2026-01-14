// Edge Function: cancel-order
// Gestion sécurisée des annulations de commande
// Bloque les annulations après pickup (règle métier critique)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Statuts où l'annulation est INTERDITE
const NON_CANCELLABLE_STATUSES = ['picked_up', 'delivering', 'delivered']

// Qui peut annuler à quel moment
const CANCELLATION_RULES: Record<string, string[]> = {
  'pending': ['customer', 'restaurant'],
  'confirmed': ['customer', 'restaurant'],
  'preparing': ['restaurant'],  // Client ne peut plus annuler une fois en préparation
  'ready': [],  // Personne ne peut annuler une fois prêt
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

    const { order_id, reason } = await req.json()
    if (!order_id) {
      throw new Error('order_id est requis')
    }

    // Récupérer la commande
    const { data: order, error: orderError } = await supabaseClient
      .from('orders')
      .select('*, restaurant:restaurants(owner_id), livreur:livreurs(user_id)')
      .eq('id', order_id)
      .single()

    if (orderError || !order) {
      throw new Error('Commande non trouvée')
    }

    const currentStatus = order.status

    // RÈGLE CRITIQUE: Bloquer après pickup
    if (NON_CANCELLABLE_STATUSES.includes(currentStatus)) {
      throw new Error(`Impossible d'annuler: commande déjà en livraison (statut: ${currentStatus})`)
    }

    // Déjà annulée ou livrée
    if (currentStatus === 'cancelled') {
      throw new Error('Commande déjà annulée')
    }

    // Récupérer le rôle
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    const userRole = profile?.role

    // Vérifier les permissions d'annulation
    const allowedRoles = CANCELLATION_RULES[currentStatus] || []
    if (!allowedRoles.includes(userRole)) {
      throw new Error(`Rôle ${userRole} non autorisé pour annuler au statut ${currentStatus}`)
    }

    // Vérifier que l'utilisateur est bien impliqué dans la commande
    let isAuthorized = false
    let cancelledBy = ''

    if (userRole === 'customer' && order.customer_id === user.id) {
      isAuthorized = true
      cancelledBy = 'customer'
    } else if (userRole === 'restaurant' && order.restaurant?.owner_id === user.id) {
      isAuthorized = true
      cancelledBy = 'restaurant'
    }

    if (!isAuthorized) {
      throw new Error('Vous n\'êtes pas autorisé à annuler cette commande')
    }

    // Effectuer l'annulation
    const { error: updateError } = await supabaseClient
      .from('orders')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancellation_reason: reason || 'Annulé par ' + cancelledBy,
        cancelled_by: cancelledBy,
      })
      .eq('id', order_id)

    if (updateError) {
      throw new Error(`Erreur annulation: ${updateError.message}`)
    }

    // Si un livreur était assigné, le libérer
    if (order.livreur_id) {
      await supabaseClient
        .from('livreurs')
        .update({ is_available: true })
        .eq('id', order.livreur_id)
    }

    // TODO: Créer une notification pour les parties concernées
    // TODO: Gérer le remboursement si paiement en ligne

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Commande annulée avec succès',
        order_id,
        cancelled_by: cancelledBy,
        previous_status: currentStatus
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
