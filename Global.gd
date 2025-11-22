class_name Global

# ENUM para modos de jogo
enum GameMode { ARCADE, VERSUS, TRAINING }
enum GameState { MENU, CHARACTER_SELECT, STAGE_SELECT, BATTLE, CUTSCENE }

# VARIÁVEIS DO JOGADOR
static var selected_character_path: String = ""
static var selected_character_data: CharacterData = null
static var selected_stage: String = "campus_unifeob"

# SISTEMA DE MODO DE JOGO
static var game_mode: GameMode = GameMode.ARCADE
static var game_state: GameState = GameState.MENU

# SISTEMA DE DIFICULDADE
static var difficulty_level: int = 1  # 0=Fácil, 1=Médio, 2=Difícil, 3=Mestre

# SISTEMA DE ARCADE MODE
static var arcade_enemies: Array = []
static var arcade_current_stage: int = 0
static var arcade_player_character: String = ""
static var arcade_score: int = 0
static var arcade_wins: int = 0
static var arcade_lives: int = 3

# --- NOVO: CENA DE GAME OVER ---
static var game_over_scene: PackedScene = preload("res://Cenas/Game_Over/game_over.tscn")

# --- NOVO: CENÁRIOS FINAIS DO PERSONAGEM ---
# Variável para armazenar o caminho da cena final (Cutscene) a ser carregada
static var current_ending_scene_path: String = ""

# CORREÇÃO CRÍTICA DE CAMINHOS/NOMES:
# Mantemos a chave "CARLOS" para consistência com all_characters, 
# mas forçamos o nome do arquivo para carlao_final.tscn.
static var character_endings = {
	"MARUDI": "res://HISTORIA/marudi_final.tscn",
	"MARCELO": "res://HISTORIA/marcelo_final.tscn",
	"CARLOS": "res://HISTORIA/carlao_final.tscn", # <-- AGORA BUSCA PELO ARQUIVO CORRETO
	"LUIS": "res://HISTORIA/luis_final.tscn"
}
# ----------------------------------------

# Dicionário com todos os personagens disponíveis
static var all_characters = {
	"MARUDI": "res://resources/characters/marudi_data.tres",
	"MARCELO": "res://resources/characters/marcelo_data.tres",
	"CARLOS": "res://resources/characters/carlos_data.tres",
	"LUIS": "res://resources/characters/luis_data.tres"
}

# Configurações de áudio
static var master_volume: float = 1.0
static var music_volume: float = 1.0
static var sfx_volume: float = 1.0

# Função chamada quando o nó é carregado
func _ready():
	# Inicializar configurações
	load_settings()
	
	print("🎮 Global.gd inicializado")

# 🎯 INICIA MODO ARCADE - VERSÃO CORRIGIDA
static func start_arcade_mode(player_character: String, enemies: Array):
	print("🎮 INICIANDO MODO ARCADE...")
	
	# Configura variáveis do Arcade
	arcade_mode = true
	game_mode = GameMode.ARCADE
	arcade_player_character = player_character
	arcade_enemies = enemies
	arcade_current_stage = 0
	arcade_score = 0
	arcade_wins = 0
	arcade_lives = 3
	
	# Encontra o caminho do personagem baseado no nome
	var character_path = ""
	for char_name in all_characters:
		if char_name == player_character:
			character_path = all_characters[char_name]
			break
	
	if character_path != "":
		selected_character_path = character_path
		if ResourceLoader.exists(character_path):
			selected_character_data = load(character_path)
			print("✅ Dados do personagem carregados: ", selected_character_data.character_name)
	else:
		print("❌ ERRO: Personagem não encontrado: ", player_character)
	
	print("🎮 MODO ARCADE CONFIGURADO:")
	print("   Jogador: ", player_character)
	print("   Caminho: ", selected_character_path)
	print("   Inimigos: ", enemies)
	print("   Total de fases: ", enemies.size())
	print("   Fase atual: ", arcade_current_stage + 1)
	print("   Dificuldade: ", _get_difficulty_name())

# 🎯 AVANÇA PARA PRÓXIMA FASE DO ARCADE
static func advance_arcade_stage():
	arcade_current_stage += 1
	arcade_wins += 1
	arcade_score += 1000 # Pontuação por fase
	
	print("🎯 Fase avançada! Fase atual: ", arcade_current_stage)
	print("   Vitórias: ", arcade_wins)
	print("   Pontuação: ", arcade_score)
	
	# Mostra informações do próximo inimigo se houver
	if arcade_current_stage < arcade_enemies.size():
		var next_enemy = arcade_enemies[arcade_current_stage]
		if ResourceLoader.exists(next_enemy):
			var enemy_data = load(next_enemy)
			if enemy_data:
				print("🎯 Próximo inimigo: ", enemy_data.character_name)

# 🎯 VERIFICA SE ARCADE FOI COMPLETADO
static func is_arcade_completed() -> bool:
	return arcade_current_stage >= arcade_enemies.size()

# 🎯 RETORNA INIMIGO ATUAL DO ARCADE
static func get_current_enemy_path() -> String:
	if arcade_enemies.size() > arcade_current_stage:
		return arcade_enemies[arcade_current_stage]
	return ""

# 🎯 RETORNA NOME DO INIMIGO ATUAL
static func get_current_enemy_name() -> String:
	var current_enemy = get_current_enemy_path()
	if current_enemy != "" and ResourceLoader.exists(current_enemy):
		var enemy_data = load(current_enemy)
		if enemy_data:
			return enemy_data.character_name
	return "Desconhecido"

# 🎯 RETORNA INFORMAÇÕES DA FASE ATUAL PARA O HUD
static func get_arcade_stage_info() -> Dictionary:
	return {
		"current_stage": arcade_current_stage + 1,
		"total_stages": arcade_enemies.size(),
		"enemy_name": get_current_enemy_name(),
		"player_name": arcade_player_character,
		"player_lives": arcade_lives,
		"player_score": arcade_score,
		"difficulty": _get_difficulty_name()
	}

# 🎯 FINALIZA MODO ARCADE (Geralmente chamada após a Cutscene ou Game Over)
static func end_arcade_mode():
	print("🎮 Modo arcade finalizado")
	print("🏆 Vitórias: ", arcade_wins, "/", arcade_enemies.size())
	print("💰 Pontuação final: ", arcade_score)
	print("🎯 Dificuldade: ", _get_difficulty_name())
	# Não chama reset_game() aqui para permitir que a Cutscene/Game Over lide com isso
	# O reset é feito ao retornar ao menu principal

# 🎯 REINICIA TODAS AS VARIÁVEIS DO JOGO
static func reset_game():
	selected_character_path = ""
	selected_character_data = null
	selected_stage = "campus_unifeob"
	game_mode = GameMode.ARCADE
	game_state = GameState.MENU
	arcade_enemies.clear()
	arcade_current_stage = 0
	arcade_player_character = ""
	arcade_score = 0
	arcade_wins = 0
	arcade_lives = 3
	# --- NOVO: Limpa o caminho da cena final ---
	current_ending_scene_path = ""
	# -------------------------------------------
	
	print("🔄 Jogo reiniciado")

# 🎯 VERIFICA SE PERSONAGEM ESTÁ CARREGADO CORRETAMENTE
static func is_character_loaded() -> bool:
	return selected_character_path != "" and ResourceLoader.exists(selected_character_path)

# 🎯 SALVA CONFIGURAÇÕES
static func save_settings():
	var config = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"difficulty_level": difficulty_level
	}
	
	var config_file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if config_file:
		config_file.store_var(config)
		config_file.close()
		print("💾 Configurações salvas")

# 🎯 CARREGA CONFIGURAÇÕES
static func load_settings():
	var config_file = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if config_file:
		var config = config_file.get_var()
		config_file.close()
		
		if config is Dictionary:
			master_volume = config.get("master_volume", 1.0)
			music_volume = config.get("music_volume", 1.0)
			sfx_volume = config.get("sfx_volume", 1.0)
			difficulty_level = config.get("difficulty_level", 1)  # Padrão: Médio
			print("💾 Configurações carregadas")
	else:
		print("⚠️ Arquivo de configurações não encontrado, usando padrões")

# 🎯 FUNÇÕES DE COMPATIBILIDADE (para código existente)

# Compatibilidade com código antigo - NÃO USAR (usar start_arcade_mode com parâmetros)
static func setup_arcade_mode(character_path: String):
	print("⚠️ AVISO: setup_arcade_mode está obsoleto, use start_arcade_mode")
	# Tenta encontrar o nome do personagem pelo caminho
	var char_name = "Desconhecido"
	for name in all_characters:
		if all_characters[name] == character_path:
			char_name = name
			break
	
	# Chama a nova função com parâmetros vazios (não ideal)
	start_arcade_mode(char_name, [])

# Compatibilidade com código antigo
static func next_arcade_stage() -> bool:
	advance_arcade_stage()
	return not is_arcade_completed()

# 🎯 PROPRIEDADE DE COMPATIBILIDADE
static var arcade_mode: bool:
	get:
		return game_mode == GameMode.ARCADE
	set(value):
		game_mode = GameMode.ARCADE if value else GameMode.VERSUS

# 🎯 PROPRIEDADE DE COMPATIBILIDADE
static var player_character_name: String:
	get:
		return arcade_player_character if arcade_player_character != "" else "Desconhecido"
	set(value):
		# Esta propriedade é apenas para leitura, mas mantemos para compatibilidade
		pass

# 🎯 FUNÇÃO PARA DEBUG
static func print_debug_info():
	print("=== DEBUG GLOBAL ===")
	print("Modo de Jogo: ", game_mode)
	print("Estado do Jogo: ", game_state)
	print("Personagem Selecionado: ", selected_character_path)
	print("Personagem Arcade: ", arcade_player_character)
	print("Cenário: ", selected_stage)
	print("Fase Arcade: ", arcade_current_stage + 1, "/", arcade_enemies.size())
	print("Vidas: ", arcade_lives)
	print("Vitórias: ", arcade_wins)
	print("Pontuação: ", arcade_score)
	print("Dificuldade: ", _get_difficulty_name(), " (", difficulty_level, ")")
	print("Inimigos: ", arcade_enemies)
	print("Cena Final: ", current_ending_scene_path) # Debug da nova variável
	print("===================")

# 🎯 NOVA FUNÇÃO: Reinicia apenas o Arcade (mantém personagem)
static func restart_arcade():
	print("🔄 Reiniciando Arcade Mode...")
	arcade_current_stage = 0
	arcade_wins = 0
	arcade_lives = 3
	arcade_score = 0
	current_ending_scene_path = "" # Limpa a variável
	
	print("🎮 Arcade reiniciado!")
	print("   Personagem: ", arcade_player_character)
	print("   Fases: ", arcade_enemies.size())
	print("   Dificuldade: ", _get_difficulty_name())

# 🎯 FUNÇÃO PARA O LEVEL - Configura inimigo atual
static func setup_current_enemy() -> CharacterData:
	var enemy_path = get_current_enemy_path()
	if enemy_path != "" and ResourceLoader.exists(enemy_path):
		var enemy_data = load(enemy_path)
		if enemy_data:
			print("🎯 Inimigo da fase configurado: ", enemy_data.character_name)
			return enemy_data
	
	print("❌ ERRO: Não foi possível carregar dados do inimigo")
	return null

# 🎯 FUNÇÃO PARA VITÓRIA NO ARCADE
static func on_arcade_victory():
	print("🏆 Vitória na fase do arcade!")
	
	# Primeiro avança a fase e contabiliza a pontuação
	advance_arcade_stage()
	
	if is_arcade_completed():
		print("🏆🏆🏆 VITÓRIA NO MODO ARCADE! Preparando final...")
		start_character_ending() # Chamar a função de cena final
	else:
		print("🎯 Próxima fase: ", get_current_enemy_name())

# 🎯 NOVA FUNÇÃO: INICIA A CENA FINAL DO PERSONAGEM
static func start_character_ending():
	# Busca o caminho da cena final baseado no personagem atual do arcade
	var ending_path = character_endings.get(arcade_player_character)
	
	if ending_path:
		current_ending_scene_path = ending_path
		game_state = GameState.CUTSCENE # Altera o estado do jogo
		print("🎬 INICIANDO CENA FINAL: Personagem '", arcade_player_character, "'. Cena: ", ending_path)
		# A sua classe de gerenciamento de cenas (SceneManager) deve agora verificar
		# se Global.game_state == Global.GameState.CUTSCENE e carregar current_ending_scene_path
	else:
		print("❌ ERRO: Caminho da cena final não encontrado para: ", arcade_player_character)
		# Se não houver ending, finaliza o modo arcade imediatamente
		end_arcade_mode()

# 🎯 FUNÇÃO PARA DERROTA NO ARCADE
static func on_arcade_defeat():
	arcade_lives -= 1
	print("💀 Derrota na fase! Vidas restantes: ", arcade_lives)
	
	if arcade_lives <= 0:
		print("💀💀💀 GAME OVER - Fim do Arcade")
		# Aqui você pode adicionar lógica para tela de game over e chamar end_arcade_mode()
	else:
		print("🔄 Continuando com ", arcade_lives, " vidas")

# 🎯 FUNÇÕES DE DIFICULDADE
static func _get_difficulty_name() -> String:
	match difficulty_level:
		0: return "FÁCIL"
		1: return "MÉDIO"
		2: return "DIFÍCIL"
		3: return "MESTRE"
		_: return "MÉDIO"

static func set_difficulty(level: int):
	difficulty_level = clamp(level, 0, 3)
	print("🎯 Dificuldade definida para: ", _get_difficulty_name())

static func get_difficulty() -> int:
	return difficulty_level
