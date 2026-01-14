// Edge Function: change-order-status
// Source unique de vérité pour les transitions de statut de commande
// Standard Uber/Deliveroo - Sécurité maximale

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Transitions autorisées (RÈGLE MÉTIER STRICTE)
const VALID_TRANSITIONS: Record<string, string[]> = {
  'pending': ['confirmed', 'cancelled'],
  'confirmed': ['preparing', 'cancelled'],
  'preparing': ['ready', 'cancelled'],
  'ready': ['picked_up'],
  'picked_up': ['delivering', 'delivered'],
  'delivering': ['delivered'],
}

// Rôles autorisés pour chaque transition
const ROLE_PERMISSIONS: Record<string, string[]> = {
  'pending->confirmed': ['livreur'],      // Livreur accepte
  'pending->cancelled': ['customer', 'restaurant'],
  'confirmed->preparing': ['restaurant'],  // Restaurant commence
  'confirmed->cancelled': ['customer', 'restaurant'],
  'preparing->ready': ['restaurant'],      // Restaurant termine
  'preparing->cancelled': ['restaurant'],
  'ready->picked_up': ['livreur'],         // Livreur récupère
  'picked_up->delivering': ['livreur'],
  'picked_up->delivered': ['livreur'],     // Livraison directe
  'delivering->delivered': ['livreur'],
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Récupérer le token JWT de l'utilisateur
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Authorization header manquant')
    }

    // Vérifier l'utilisateur
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (authError || !user) {
      throw new Error('Utilisateur non authentifié')
    }

    // Récupérer les paramètres
    const { order_id, new_status } = await req.json()
    if (!order_id || !new_status) {
      throw new Error('order_id et new_status sont requis')
    }

    // Récupérer la commande actuelle
    const { data: order, error: orderError } = await supabaseClient
      .from('orders')
      .select('*, restaurant:restaurants(owner_id)')
      .eq('id', order_id)
      .single()

    if (orderError || !order) {
      throw new Error('Commande non trouvée')
    }

    const currentStatus = order.status

    // Vérifier si la transition est valide
    if (!VALID_TRANSITIONS[currentStatus]?.includes(new_status)) {
      throw new Error(`Transition invalide: ${currentStatus} → ${new_status}`)
    }

    // Récupérer le rôle de l'utilisateur
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    const userRole = profile?.role

    // Vérifier les permissions de rôle
    const transitionKey = `${currentStatus}->${new_status}`
    const allowedRoles = ROLE_PERMISSIONS[transitionKey]
    
    if (!allowedRoles?.includes(userRole)) {
      throw new Error(`Rôle ${userRole} non autorisé pour cette transition`)
    }

    // Vérifications supplémentaires selon le rôle
    if (userRole === 'customer' && order.customer_id !== user.id) {
      throw new Error('Vous ne pouvez modifier que vos propres commandes')
    }

    if (userRole === 'restaurant' && order.restaurant?.owner_id !== user.id) {
      throw new Error('Vous ne pouvez modifier que les commandes de votre restaurant')
    }

    if (userRole === 'livreur') {
      const { data: livreur } = await supabaseClient
        .from('livreurs')
        .select('id, is_verified')
        .eq('user_id', user.id)
        .single()

      if (!livreur?.is_verified) {
        throw new Error('Livreur non vérifié')
      }

      // Pour accepter une commande pending
      if (currentStatus === 'pending' && new_status === 'confirmed') {
        if (order.livreur_id !== null) {
          throw new Error('Commande déjà acceptée par un autre livreur')
        }
      } else if (order.livreur_id !== livreur.id) {
        throw new Error('Vous ne pouvez modifier que vos commandes assignées')
      }
    }

    // Préparer les mises à jour
    const updates: Record<string, any> = { status: new_status }
    const now = new Date().toISOString()

    // Ajouter les timestamps selon le statut
    switch (new_status) {
      case 'confirmed':
        updates.confirmed_at = now
        if (userRole === 'livreur') {
          // Livreur accepte la commande
          const { data: livreur } = await supabaseClient
            .from('livreurs')
            .select('id')
            .eq('user_id', user.id)
            .single()
          updates.livreur_id = livreur?.id
          updates.livreur_accepted_at = now
          
          // Marquer le livreur comme non disponible
          await supabaseClient
            .from('livreurs')
            .update({ is_available: false })
            .eq('user_id', user.id)
        }
        break
      case 'preparing':
        updates.preparing_at = now
        break
      case 'ready':
        updates.prepared_at = now
        break
      case 'picked_up':
        updates.picked_up_at = now
        break
      case 'delivered':
        updates.delivered_at = now
        // Libérer le livreur
        if (order.livreur_id) {
          const { data: livreur } = await supabaseClient
            .from('livreurs')
            .select('user_id')
            .eq('id', order.livreur_id)
            .single()
          if (livreur) {
            await supabaseClient
              .from('livreurs')
              .update({ is_available: true })
              .eq('id', order.livreur_id)
          }
        }
        break
    }

    // Appliquer la mise à jour
    const { error: updateError } = await supabaseClient
      .from('orders')
      .update(updates)
      .eq('id', order_id)

    if (updateError) {
      throw new Error(`Erreur mise à jour: ${updateError.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Statut changé: ${currentStatus} → ${new_status}`,
        order_id,
        new_status 
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
