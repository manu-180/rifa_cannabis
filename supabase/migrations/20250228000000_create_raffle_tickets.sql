-- Tabla: números de la rifa (1 a 100). Cada fila = un número vendido a un comprador.
CREATE TABLE IF NOT EXISTS public.raffle_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  number int NOT NULL CHECK (number >= 1 AND number <= 100),
  buyer_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(number)
);

-- Índices para consultas por nombre (estadísticas) y por número (talonario).
CREATE INDEX IF NOT EXISTS idx_raffle_tickets_buyer ON public.raffle_tickets(buyer_name);
CREATE INDEX IF NOT EXISTS idx_raffle_tickets_number ON public.raffle_tickets(number);

-- RLS: lectura pública (talonario y estadísticas); escritura solo autenticados (admin).
ALTER TABLE public.raffle_tickets ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede ver todos los números y compradores (talonario público).
DROP POLICY IF EXISTS "raffle_tickets_select_all" ON public.raffle_tickets;
CREATE POLICY "raffle_tickets_select_all" ON public.raffle_tickets
  FOR SELECT USING (true);

-- Solo usuarios autenticados pueden insertar (asignar números como admin).
DROP POLICY IF EXISTS "raffle_tickets_insert_auth" ON public.raffle_tickets;
CREATE POLICY "raffle_tickets_insert_auth" ON public.raffle_tickets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Solo usuarios autenticados pueden actualizar (cambiar asignación).
DROP POLICY IF EXISTS "raffle_tickets_update_auth" ON public.raffle_tickets;
CREATE POLICY "raffle_tickets_update_auth" ON public.raffle_tickets
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Solo usuarios autenticados pueden eliminar.
DROP POLICY IF EXISTS "raffle_tickets_delete_auth" ON public.raffle_tickets;
CREATE POLICY "raffle_tickets_delete_auth" ON public.raffle_tickets
  FOR DELETE USING (auth.role() = 'authenticated');

COMMENT ON TABLE public.raffle_tickets IS 'Números 1-100 de la rifa. Cada número tiene un comprador (buyer_name).';
