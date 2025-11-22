# MatchData.gd
# Este é o Singleton (AutoLoad) que armazena todas as
# regras carregadas da sua DSL.
extends Node

# --- VARIÁVEIS DA TELA DE SELEÇÃO (Seu código original) ---
var player1_portrait_path: String
var player2_portrait_path: String
var player1_scene_path: String
var player2_scene_path: String

# --- VARIÁVEIS DA DSL (Nosso novo código) ---

# 1. Para 'define_match_rules'
# Valores padrão caso o .txt falhe
var match_rules = {
	"health_p1": 100,
	"health_p2": 100,
	"rounds_to_win": 2,
	"round_timer": 99
}

# 2. Para 'define_combo_rules'
var combo_rules = {
	"max_time_window": 2.0,
	"break_on_hit_taken": true
}

# 3. Para 'define_combo_milestone'
# Armazena {5: "GREAT!", 10: "AWESOME!"}
var combo_milestones = {}

# 4. Para 'define_attack'
# Armazena { "player_1": {"soco_fraco": 5}, "player_2": {"soco_fraco": 6} }
var attack_damage = {
	"player_1": {},
	"player_2": {}
}

# 5. Para 'define_special'
# Armazena { "hadouken": {name: "hadouken", ...}, ... }
var special_moves = {}

# --- FUNÇÃO DE CARREGAMENTO DA DSL (Executa 1 vez no início) ---
func _ready():
	print("MatchData Singleton pronto. Carregando regras da DSL...")
	
	# Caminhos para os arquivos da DSL.
	# **AJUSTE AQUI** se seus arquivos estiverem em outra pasta (ex: "res://scripts/")
	var analisador_path = "res://analisador.gd"
	var regras_path = "res://teste_sucesso.txt"
	
	# Carrega o script do analisador
	var loader = load(analisador_path)
	var success = false
	
	if loader:
		var parser_script = loader.new()
		# Prepara os argumentos para o analisador
		var args = ["", regras_path] 
		# Chama a função que lê o arquivo e NÃO fecha o jogo
		success = parser_script.call("_run_from_game", args)
	else:
		printerr("FALHA CRÍTICA: Não foi possível carregar o 'analisador.gd' em: ", analisador_path)

	if success:
		print("--- SUCESSO! Regras da DSL carregadas no MatchData. ---")
	else:
		printerr("--- FALHA AO CARREGAR DSL! Verifique o 'analisador.gd' e '", regras_path, "'. Usando regras padrão. ---")


# --- Funções da DSL ---
# Esta função é chamada pelo analisador quando ele encontra 'execute_special'
func register_special_move_attempt(player, sequence):
	print("REGISTRO DSL: Jogador '", player, "' tentou a sequência: ", sequence)
	# No futuro, o script do Player pode ouvir um sinal daqui
	# emit_signal("special_move_attempted", player, sequence)
