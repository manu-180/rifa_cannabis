-- Resultado del sorteo: un único registro por sorteo (el más reciente es el vigente).
CREATE TABLE IF NOT EXISTS public.raffle_draw (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  winner_name text NOT NULL,
  winning_number int NOT NULL,
  section_index int NOT NULL,
  drawn_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_raffle_draw_drawn_at ON public.raffle_draw(drawn_at DESC);

-- Lectura pública para que todos vean el ganador.
ALTER TABLE public.raffle_draw ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "raffle_draw_select_all" ON public.raffle_draw;
CREATE POLICY "raffle_draw_select_all" ON public.raffle_draw
  FOR SELECT USING (true);

-- Cualquiera puede insertar (el sorteo se dispara en el cliente cuando llega la hora).
DROP POLICY IF EXISTS "raffle_draw_insert_all" ON public.raffle_draw;
CREATE POLICY "raffle_draw_insert_all" ON public.raffle_draw
  FOR INSERT WITH CHECK (true);

COMMENT ON TABLE public.raffle_draw IS 'Resultado del sorteo: ganador, número ganador e índice del segmento (para la aguja).';
