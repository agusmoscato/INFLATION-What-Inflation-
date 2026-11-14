extends Node
## Bus global de señales. Desacopla la lógica (Economy) de la interfaz.

signal clicked(result: Dictionary)          ## {value, crit, combo}
signal business_bought(id: String, amount: int)
signal milestone(id: String, count: int)
signal upgrade_bought(id: String)
signal node_bought(id: String)
signal remarked(seconds: float, manual: bool)
signal bill_spawn(bill_id: int)
signal bill_missed(bill_id: int)
signal bill_prize(result: Dictionary)
signal event_choice(id: String)             ## se abrió una noticia (10 s para elegir)
signal event_choice_done(id: String, idx: int)
signal event_ended(id: String)
signal unlock(feature: String)
signal collapse                             ## "¡La economía colapsó! Hacé la reforma"
signal page_done(page: int)
signal pack_opened
signal sticker_won(id: String)
signal secret_end
signal scratched(result: Dictionary)
signal reform_done(summary: Dictionary)
signal achievement_unlocked(id: String)
signal victory
signal demo_end                             ## la demo llegó a su límite
signal offline_report(report: Dictionary)
signal game_loaded
signal toast(text: String)
