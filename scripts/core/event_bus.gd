extends Node
## Bus global de señales. Desacopla la lógica (Economy) de la interfaz.

signal money_changed
signal business_bought(id: String, amount: int)
signal upgrade_bought(id: String)
signal clicked(amount: BigNumber)
signal month_passed(rate: float)            ## "¡Aumento!"
signal remarked(bonus: BigNumber, on_time: bool)
signal era_changed(era: int)
signal event_started(id: String)
signal event_ended(id: String)
signal event_choice(id: String)             ## se abrió una decisión (10 s para elegir)
signal event_choice_done(id: String, idx: int)
signal refuge_changed
signal reform_done(banknote_id: int, cut_zeros: int)
signal plan_done(plan_id: String)
signal achievement_unlocked(id: String)
signal victory
signal demo_end                              ## la demo llegó a su límite
signal headline(text_key: String)
signal offline_report(report: Dictionary)
signal game_loaded
signal toast(text: String)
