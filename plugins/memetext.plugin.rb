class Memetext < Plugin

  def initialize(bot)
    super(bot)
    @rmap = {
      "\u{0041}" => "\u{ff21}", "\u{0042}" => "\u{ff22}", "\u{0043}" => "\u{ff23}",
      "\u{0044}" => "\u{ff24}", "\u{0045}" => "\u{ff25}", "\u{0046}" => "\u{ff26}",
      "\u{0047}" => "\u{ff27}", "\u{0048}" => "\u{ff28}", "\u{0049}" => "\u{ff29}",
      "\u{004a}" => "\u{ff2a}", "\u{004b}" => "\u{ff2b}", "\u{004c}" => "\u{ff2c}",
      "\u{004d}" => "\u{ff2d}", "\u{004e}" => "\u{ff2e}", "\u{004f}" => "\u{ff2f}",
      "\u{0050}" => "\u{ff30}", "\u{0051}" => "\u{ff31}", "\u{0052}" => "\u{ff32}",
      "\u{0053}" => "\u{ff33}", "\u{0054}" => "\u{ff34}", "\u{0055}" => "\u{ff35}",
      "\u{0056}" => "\u{ff36}", "\u{0057}" => "\u{ff37}", "\u{0058}" => "\u{ff38}",
      "\u{0059}" => "\u{ff39}", "\u{005a}" => "\u{ff3a}", "\u{0061}" => "\u{ff41}",
      "\u{0062}" => "\u{ff42}", "\u{0063}" => "\u{ff43}", "\u{0064}" => "\u{ff44}",
      "\u{0065}" => "\u{ff45}", "\u{0066}" => "\u{ff46}", "\u{0067}" => "\u{ff47}",
      "\u{0068}" => "\u{ff48}", "\u{0069}" => "\u{ff49}", "\u{006a}" => "\u{ff4a}",
      "\u{006b}" => "\u{ff4b}", "\u{006c}" => "\u{ff4c}", "\u{006d}" => "\u{ff4d}",
      "\u{006e}" => "\u{ff4e}", "\u{006f}" => "\u{ff4f}", "\u{0070}" => "\u{ff50}",
      "\u{0071}" => "\u{ff51}", "\u{0072}" => "\u{ff52}", "\u{0073}" => "\u{ff53}",
      "\u{0074}" => "\u{ff54}", "\u{0075}" => "\u{ff55}", "\u{0076}" => "\u{ff56}",
      "\u{0077}" => "\u{ff57}", "\u{0078}" => "\u{ff58}", "\u{0079}" => "\u{ff59}",
      "\u{007a}" => "\u{ff5a}"
    }
    @cmap = {}
    @rmap.each_pair{|k, v|
      if !@rmap[v]
        @cmap[@rmap[k]] = k
      end
      @cmap[k] = v
    }
  end

  def meme(user, args)
    mem = ""
    args.each_char{|c|
      if @cmap[c]
        mem += @cmap[c]
      else
        mem += c
      end
    }
    @bot.say(mem)
  end

  def register_functions
    register_command('meme', USER::ALL, 'memetext')
  end
end
