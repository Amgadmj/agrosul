# Certificado — a strategic product concept

`Certificado_Deck.pptx` is a strategic concept deck, not a committed roadmap. It answers one
question: what happens if we point Agrostech's Geomart data engine and Agrosul's Swarm platform
at Brazil's 3.9 million smallholder family farms instead of only at mid/large producers?

## The synthesis

- **From Agrostech**: `runner/geomart_client.py` and `runner/mapbiomas_client.py` already pull
  SIGEF-certified parcels and MapBiomas alerts to source enterprise sales leads. The pricing model
  in `knowledge-base/PRICING_MODEL.md` already prices NDVI/NDRE at R$22–60/ha and carbon MRV laudos
  at R$8,000–20,000 — built for 500–50,000 ha operations.
- **From Agrosul**: the Swarm agents (`backend/swarm/agents/solis.py`, `mercurius_plutus.py`)
  already watch Sentinel-2 NDVI for >15% health drops and gate every mission by ROI. The per-hectare
  report pricing in `portal/src/lib/mockData.ts` (NDVI/VRT at $1.20/ha) already reflects how cheap
  open-data-driven monitoring can be.
- **From the open-data land-market thesis** (multi-agent automation over SIGEF / SICAR / MapBiomas
  for Brazilian land transactions): the same signal-to-execution pattern — data agent → content
  agent → distribution agent → monitoring/feedback agent — repurposed from B2B lead generation into
  a self-serve compliance product for the smallholder segment neither company currently reaches.

## The product

**Certificado**: an automated compliance and crop-health certificate, generated entirely from free
public data (SIGEF boundary certification, SICAR/CAR status, MapBiomas deforestation alerts,
Sentinel-2 NDVI), delivered and renewed over WhatsApp — no dashboard, no drone flight, no paid
imagery required. It is designed as the free/low-cost top of a funnel that upsells into Agrosul's
paid Swarm monitoring and, further, into Agrostech's carbon/ESG MRV laudos.

## Why open data, not commercial imagery

Sentinel-2 (10 m, 5-day revisit) is free and sufficient for the decisions Certificado supports
(credit eligibility, deforestation-free proof, health trend). Commercial very-high-resolution
tasking (Maxar/Pléiades, 30–50 cm) runs $40–60/km² with a 50 km² order minimum — about $2,000+
per order, or roughly 250× the land area of an average 20-hectare family farm, just to meet the
minimum. The full cost comparison and regulatory context (Brazil's January 2026 CAR-linked credit
rule, the EU Deforestation Regulation's December 2026 deadline) are in the deck.

## Status

Concept only. No branch, code, or prior design work existed for this idea in either repository
before this deck — see the deck's roadmap slide for a proposed three-phase path (pilot, distribute,
compound) if the concept is worth pursuing.
