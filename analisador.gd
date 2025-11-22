# analisador.gd - VERSÃO REATORADA FINAL
# Este script lê o arquivo .txt e carrega os dados no Singleton 'MatchData'.
extends SceneTree

# --- 1. DEFINIÇÃO DOS TOKENS ---
enum TokenType{
	# Comandos da DSL (Todos novos)
	DEFINE_MATCH_RULES,
	DEFINE_COMBO_RULES,
	DEFINE_COMBO_MILESTONE,
	DEFINE_ATTACK,
	DEFINE_SPECIAL,
	EXECUTE_SPECIAL,
	
	# Palavras-chave e Valores
	IDENTIFIER,
	INTEGER,
	STRING,
	PLAYER_ID,
	FLOAT,
	BOOLEAN,
	
	# Símbolos
	LPAREN, RPAREN, LBRACKET, RBRACKET, EQUALS, COMMA,
	
	# Controle
	EOF
}

class Token:
	var type: TokenType
	var value
	func _init(p_type: TokenType, p_value = null):
		self.type = p_type
		self.value = p_value
	# Corrigido para _to_string() para evitar conflito com Godot 4
	func _to_string() -> String:
		return "Token({type}, {value})".format({"type": TokenType.keys()[type], "value": value})

# --- 2. ANÁLISE LÉXICA (TOKENIZER) ---
func tokenize(source: String) -> Array[Token]:
	var tokens: Array[Token] = []
	var current = 0
	var letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	
	while current < source.length():
		var char = source[current]
		
		# Ignora espaços em branco
		if char == ' ' or char == '\t' or char == '\n' or char == '\r':
			current += 1; continue
		
		# Símbolos
		match char:
			'(': tokens.push_back(Token.new(TokenType.LPAREN, char)); current += 1; continue
			')': tokens.push_back(Token.new(TokenType.RPAREN, char)); current += 1; continue
			'[': tokens.push_back(Token.new(TokenType.LBRACKET, char)); current += 1; continue
			']': tokens.push_back(Token.new(TokenType.RBRACKET, char)); current += 1; continue
			'=': tokens.push_back(Token.new(TokenType.EQUALS, char)); current += 1; continue
			',': tokens.push_back(Token.new(TokenType.COMMA, char)); current += 1; continue
		
		# Strings
		if char == '"':
			var str_value = ""; current += 1
			while current < source.length() and source[current] != '"':
				str_value += source[current]; current += 1
			if current >= source.length(): push_error("Erro Léxico: String não fechada."); return []
			current += 1; tokens.push_back(Token.new(TokenType.STRING, str_value)); continue
		
		# Números (Integer e Float)
		if char.is_valid_int() or (char == '.' and current + 1 < source.length() and source[current + 1].is_valid_int()):
			var num_str = ""; var has_decimal_point = false
			if char == '.': num_str = "0."; has_decimal_point = true; current += 1
			
			while current < source.length() and (source[current].is_valid_int() or source[current] == '.'):
				if source[current] == '.':
					if has_decimal_point: break
					has_decimal_point = true
				num_str += source[current]; current += 1
			
			if has_decimal_point: tokens.push_back(Token.new(TokenType.FLOAT, float(num_str)))
			else: tokens.push_back(Token.new(TokenType.INTEGER, int(num_str)))
			continue
			
		# Identificadores, Comandos, Booleans
		if letters.find(char) != -1:
			var identifier = ""
			while current < source.length() and (letters.find(source[current]) != -1 or source[current].is_valid_int() or source[current] == '_'):
				identifier += source[current]; current += 1
			
			match identifier:
				"define_match_rules": tokens.push_back(Token.new(TokenType.DEFINE_MATCH_RULES, identifier))
				"define_combo_rules": tokens.push_back(Token.new(TokenType.DEFINE_COMBO_RULES, identifier))
				"define_combo_milestone": tokens.push_back(Token.new(TokenType.DEFINE_COMBO_MILESTONE, identifier))
				"define_attack": tokens.push_back(Token.new(TokenType.DEFINE_ATTACK, identifier))
				"define_special": tokens.push_back(Token.new(TokenType.DEFINE_SPECIAL, identifier))
				"execute_special": tokens.push_back(Token.new(TokenType.EXECUTE_SPECIAL, identifier))
				"player_1", "player_2": tokens.push_back(Token.new(TokenType.PLAYER_ID, identifier))
				"true": tokens.push_back(Token.new(TokenType.BOOLEAN, true))
				"false": tokens.push_back(Token.new(TokenType.BOOLEAN, false))
				_: tokens.push_back(Token.new(TokenType.IDENTIFIER, identifier))
			continue
			
		push_error("Erro Léxico: Caractere inesperado '{char}'.".format({"char": char}))
		return []
	
	tokens.push_back(Token.new(TokenType.EOF))
	return tokens
	
# --- 3. ANÁLISE SINTÁTICA (PARSER / LOADER) ---
var tokens: Array[Token]
var pos: int
func parse(p_tokens: Array[Token]) -> bool:
	tokens = p_tokens; pos = 0
	if tokens.is_empty(): return false
	while not is_at_end():
		if not comand_parse(): return false
	return true

# --- Funções de Apoio (Helpers) ---
func parse_value():
	if peek().type in [TokenType.INTEGER, TokenType.STRING, TokenType.PLAYER_ID, TokenType.FLOAT, TokenType.BOOLEAN]:
		return advance().value
	if peek().type == TokenType.LBRACKET:
		return parse_button_list()
	push_error("Erro de Valor: Valor de parâmetro inesperado: " + peek()._to_string())
	return null

func parse_button_list() -> Array:
	var button_list = []; if not consume(TokenType.LBRACKET, "Esperado '['."): return []
	if peek().type != TokenType.RBRACKET:
		if not match_token(TokenType.IDENTIFIER): push_error("Esperado identificador de botão."); return []
		button_list.push_back(tokens[pos-1].value)
		while match_token(TokenType.COMMA):
			if not match_token(TokenType.IDENTIFIER): push_error("Esperado identificador de botão."); return []
			button_list.push_back(tokens[pos-1].value)
	if not consume(TokenType.RBRACKET, "Esperado ']'."): return []
	return button_list

func parse_list_params() -> Dictionary:
	var params = {}; if not match_token(TokenType.IDENTIFIER): push_error("Esperado nome de parâmetro."); return {}
	var key = tokens[pos-1].value; if not consume(TokenType.EQUALS, "Esperado '='."): return {}
	var value = parse_value(); if value == null: return {}
	params[key] = value
	while match_token(TokenType.COMMA):
		if not match_token(TokenType.IDENTIFIER): push_error("Esperado nome de parâmetro."); return {}
		key = tokens[pos-1].value; if not consume(TokenType.EQUALS, "Esperado '='."): return {}
		value = parse_value(); if value == null: return {}
		params[key] = value
	return params

# --- Funções de Comando (O Roteador Principal) ---
func comand_parse() -> bool:
	if match_token(TokenType.DEFINE_MATCH_RULES): return exec_define_match_rules()
	if match_token(TokenType.DEFINE_COMBO_RULES): return exec_define_combo_rules()
	if match_token(TokenType.DEFINE_COMBO_MILESTONE): return exec_define_combo_milestone()
	if match_token(TokenType.DEFINE_ATTACK): return exec_define_attack()
	if match_token(TokenType.DEFINE_SPECIAL): return exec_define_special()
	if match_token(TokenType.EXECUTE_SPECIAL): return exec_execute_special()
	push_error("Erro Sintático: Comando desconhecido: {token}".format({"token": peek()._to_string()}))
	return false

# --- Funções de Execução (Carregam os dados no MatchData) ---
func exec_define_match_rules() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params(); if params.is_empty(): return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.match_rules = params # SALVA NO SINGLETON
	print("Carregado: Regras da Partida: ", params)
	return true

func exec_define_combo_rules() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params(); if params.is_empty(): return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.combo_rules = params # SALVA NO SINGLETON
	print("Carregado: Regras de Combo: ", params)
	return true

func exec_define_combo_milestone() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params()
	if not params.has("hits") or not params.has("message"): push_error("Faltando 'hits' ou 'message'."); return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.combo_milestones[params.hits] = params.message # SALVA NO SINGLETON
	print("Carregado: Marco de Combo: ", params.hits, " hits = '", params.message, "'")
	return true

func exec_define_attack() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params()
	if not params.has("player") or not params.has("attack_name") or not params.has("damage"): push_error("Faltando 'player', 'attack_name' ou 'damage'."); return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.attack_damage[params.player][params.attack_name] = params.damage # SALVA NO SINGLETON
	print("Carregado: Ataque '", params.attack_name, "' de '", params.player, "' causa ", params.damage)
	return true

func exec_define_special() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params()
	if not params.has("name") or not params.has("sequence") or not params.has("damage"): push_error("Faltando 'name', 'sequence' ou 'damage'."); return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.special_moves[params.name] = params # SALVA NO SINGLETON
	print("Carregado: Especial '", params.name, "'")
	return true

func exec_execute_special() -> bool:
	if not consume(TokenType.LPAREN, ""): return false
	var params = parse_list_params()
	if not params.has("player") or not params.has("sequence"): push_error("Faltando 'player' ou 'sequence'."); return false
	if not consume(TokenType.RPAREN, ""): return false
	MatchData.register_special_move_attempt(params.player, params.sequence) # CHAMA O SINGLETON
	return true
	
# --- Funções de Apoio (sem alteração) ---
func peek() -> Token: return tokens[pos]
func advance() -> Token:
	if not is_at_end(): pos += 1
	return tokens[pos - 1]
func is_at_end() -> bool: return peek().type == TokenType.EOF
func consume(type: TokenType, message: String) -> bool:
	if peek().type == type: advance(); return true
	push_error("Erro Sintático: " + message); return false
func match_token(type: TokenType) -> bool:
	if peek().type == type: advance(); return true
	return false

# --- 4. PONTO DE ENTRADA (HEADLESS) ---
# Usado para testes via linha de comando
func _run():
	var arguments = OS.get_cmdline_args()
	if arguments.size() < 2:
		print("Uso: godot --headless --script analisador.gd <arquivo>"); quit(1)
	
	var file_path = arguments[arguments.size() - 1]
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not FileAccess.file_exists(file_path) or file == null:
		push_error("Erro: Não foi possível abrir o arquivo: " + file_path); quit(1)
	
	var content = file.get_as_text(); file.close()
	print("--- Iniciando análise e carregamento: {path} ---".format({"path": file_path}))
	var tokens_result = tokenize(content)
	if tokens_result.is_empty() and content.strip_edges().length() > 0:
		print("--- Análise Falhou (Erro Léxico) ---"); quit(1)

	if parse(tokens_result):
		print("--- SUCESSO: Regras do script carregadas no MatchData! ---")
		print("\nResumo das Regras Carregadas:")
		print("  Regras da Partida: ", MatchData.match_rules)
		print("  Regras de Combo: ", MatchData.combo_rules)
		print("  Marcos de Combo: ", MatchData.combo_milestones)
		print("  Dano de Ataque P1: ", MatchData.attack_damage.player_1)
		print("  Dano de Ataque P2: ", MatchData.attack_damage.player_2)
		print("  Especiais Definidos: ", MatchData.special_moves.keys())
		quit(0)
	else:
		print("--- ERRO: O script contém erros sintáticos e não foi carregado. ---")
		quit(1)

# --- 5. PONTO DE ENTRADA (DO JOGO) ---
# Chamado pelo 'MatchData.gd' para carregar as regras sem fechar o jogo
func _run_from_game(arguments: Array) -> bool:
	if arguments.size() < 2:
		push_error("analisador.gd: _run_from_game chamado sem argumentos.")
		return false

	var file_path = arguments[arguments.size() - 1]
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not FileAccess.file_exists(file_path) or file == null:
		push_error("Erro: Não foi possível abrir o arquivo: " + file_path)
		return false

	var content = file.get_as_text(); file.close()
	print("--- Iniciando análise e carregamento: {path} ---".format({"path": file_path}))
	var tokens_result = tokenize(content)
	if tokens_result.is_empty() and content.strip_edges().length() > 0:
		print("--- Análise Falhou (Erro Léxico) ---")
		return false

	if parse(tokens_result):
		# Esta função não imprime o resumo, o MatchData.gd fará isso
		return true
	else:
		print("--- ERRO: O script contém erros sintáticos e não foi carregado. ---")
		return false
