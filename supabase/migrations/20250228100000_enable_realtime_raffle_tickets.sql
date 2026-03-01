-- Habilitar Realtime en raffle_tickets para que el talonario se actualice en vivo para todos.
ALTER PUBLICATION supabase_realtime ADD TABLE public.raffle_tickets;
