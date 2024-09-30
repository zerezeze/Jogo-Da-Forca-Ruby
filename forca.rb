require 'io/console'
require 'yaml'

class JogoDaForca
  def initialize
    @palavras = carregar_palavras
    @dificuldade = escolher_dificuldade
    @palavra_secreta = escolher_palavra
    @letras_adivinhadas = Array.new(@palavra_secreta.length, "_")
    @tentativas_restantes = 6
    @letras_tentadas = []
    @pontuacao = 0
    @tempo_inicio = Time.now
    @tempo_limite = 300 # 5 minutos
    @dicas = gerar_dicas
  end

  def jogar
    puts "Bem-vindo ao Jogo da Forca!"
    puts "A palavra tem #{@palavra_secreta.length} letras."
    puts "Categoria: #{@categoria}"
    puts "Você tem 5 minutos para adivinhar a palavra."

    until jogo_terminado?
      exibir_estado_atual
      pedir_letra
    end

    exibir_resultado
    salvar_pontuacao
  end

  private

  def carregar_palavras
    YAML.load_file('palavras.yml')
  rescue Errno::ENOENT
    {
      'fácil' => {'animais' => ['gato', 'cao', 'rato'], 'frutas' => ['uva', 'kiwi', 'manga']},
      'médio' => {'países' => ['brasil', 'japao', 'egito'], 'esportes' => ['tenis', 'boxe', 'judo']},
      'difícil' => {'ciências' => ['quimica', 'biologia', 'fisica'], 'profissões' => ['advogado', 'engenheiro', 'psicologo']}
    }
  end

  def escolher_dificuldade
    puts "Escolha a dificuldade: fácil, médio ou difícil"
    loop do
      dificuldade = gets.chomp.downcase
      return dificuldade if ['fácil', 'médio', 'difícil'].include?(dificuldade)
      puts "Por favor, escolha entre fácil, médio ou difícil."
    end
  end

  def escolher_palavra
    @categoria = @palavras[@dificuldade].keys.sample
    @palavras[@dificuldade][@categoria].sample.downcase
  end

  def gerar_dicas
    case @dificuldade
    when 'fácil'
      3
    when 'médio'
      2
    when 'difícil'
      1
    end
  end

  def exibir_estado_atual
    puts "\nPalavra: #{@letras_adivinhadas.join(' ')}"
    puts "Tentativas restantes: #{@tentativas_restantes}"
    puts "Letras tentadas: #{@letras_tentadas.join(', ')}"
    puts "Pontuação atual: #{@pontuacao}"
    puts "Tempo restante: #{tempo_restante} segundos"
    puts "Dicas disponíveis: #{@dicas}"
    desenhar_forca
  end

  def desenhar_forca
    forca = [
      "  +---+",
      "  |   |",
      "  #{@tentativas_restantes < 6 ? 'O' : ' '}   |",
      " #{@tentativas_restantes < 4 ? '/' : ' '}#{@tentativas_restantes < 5 ? '|' : ' '}#{@tentativas_restantes < 3 ? '\\' : ' '}  |",
      " #{@tentativas_restantes < 2 ? '/' : ' '} #{@tentativas_restantes < 1 ? '\\' : ' '}  |",
      "      |",
      "=========",
    ]
    puts forca.join("\n")
  end

  def pedir_letra
    print "Digite uma letra (ou 'dica' para obter uma dica): "
    entrada = gets.chomp.downcase
    if entrada == 'dica'
      dar_dica
    elsif entrada.length != 1 || !entrada.match?(/[a-z]/)
      puts "Por favor, digite apenas uma letra."
    elsif @letras_tentadas.include?(entrada)
      puts "Você já tentou essa letra. Tente outra."
    else
      processar_tentativa(entrada)
    end
  end

  def dar_dica
    if @dicas > 0
      letra_nao_adivinhada = (@palavra_secreta.chars - @letras_adivinhadas).sample
      puts "Dica: A palavra contém a letra '#{letra_nao_adivinhada}'."
      @dicas -= 1
      @pontuacao -= 15
    else
      puts "Você não tem mais dicas disponíveis."
    end
  end

  def processar_tentativa(letra)
    @letras_tentadas << letra
    if @palavra_secreta.include?(letra)
      atualizar_letras_adivinhadas(letra)
      @pontuacao += 10
      tocar_som('acerto.wav')
      puts "Boa! A letra '#{letra}' está na palavra."
    else
      @tentativas_restantes -= 1
      @pontuacao -= 5
      tocar_som('erro.wav')
      puts "Ops! A letra '#{letra}' não está na palavra."
    end
  end

  def atualizar_letras_adivinhadas(letra)
    @palavra_secreta.chars.each_with_index do |char, index|
      @letras_adivinhadas[index] = letra if char == letra
    end
  end

  def jogo_terminado?
    vitoria? || derrota? || tempo_esgotado?
  end

  def vitoria?
    !@letras_adivinhadas.include?("_")
  end

  def derrota?
    @tentativas_restantes == 0
  end

  def tempo_esgotado?
    tempo_restante <= 0
  end

  def tempo_restante
    [@tempo_limite - (Time.now - @tempo_inicio), 0].max.to_i
  end

  def exibir_resultado
    if vitoria?
      @pontuacao += 50
      tocar_som('vitoria.wav')
      puts "\nParabéns! Você venceu! A palavra era: #{@palavra_secreta}"
    elsif derrota?
      tocar_som('derrota.wav')
      puts "\nGame over! A palavra era: #{@palavra_secreta}"
    else
      tocar_som('tempo_esgotado.wav')
      puts "\nTempo esgotado! A palavra era: #{@palavra_secreta}"
    end
    puts "Pontuação final: #{@pontuacao}"
  end

  def salvar_pontuacao
    File.open("pontuacoes.txt", "a") do |file|
      file.puts "#{Time.now} - Palavra: #{@palavra_secreta} - Dificuldade: #{@dificuldade} - Pontuação: #{@pontuacao}"
    end
  end

  def tocar_som(arquivo)
    system("afplay #{arquivo}") if File.exist?(arquivo)
  end
end

# Iniciar o jogo
jogo = JogoDaForca.new
jogo.jogar
