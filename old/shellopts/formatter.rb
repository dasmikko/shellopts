
require 'ext/algorithm'

require 'stringio'

module ShellOpts
  class Formatter
    # Return string describing usage of command
    def self.usage_string(command, levels: 1, margin: "")
      elements(command, levels: levels, help: false).map { |line|
        "#{margin}#{line}"
      }.join("\n")
    end

    # Return string with help for the given command
    def self.help_string(command, levels: 10, margin: "", tab: "  ")
      io = StringIO.new
      elements(command, levels: levels, help: true).each { |head, texts, options|
#       io.puts "#{margin}#{head}"
        io.print "#{margin}#{head}" # FIXME Fixture fox fix
        puts if !texts.empty? # FIXME Fixture fox fix

        texts.each { |text| io.puts "#{margin}#{tab}#{text}" }
        options.each { |opt_head, opt_texts|
          io.puts
          io.puts "#{margin}#{tab}#{opt_head}"
          opt_texts.each { |text| io.puts "#{margin}#{tab*2}#{text}" }
        }
        io.puts
      }
      io.string[0..-2]
    end

  private
    def self.elements(command, levels: 1, help: false)
      result = []
      recursive_elements(result, command, levels: levels, help: help)
      result  
    end

    def self.recursive_elements(acc, command, levels: 1, help: false)
      cmds = (command.virtual? ? command.cmds : [command])
      cmds.each { |cmd|
        if levels == 1 || cmd.cmds.empty?
          usage = (
              path_elements(cmd) + 
              option_elements(cmd) +
              subcommand_element(cmd) +
              argument_elements(cmd)
          ).compact.join(" ")
          if help
            opts = []
            cmd.opts.each { |opt|
              next if opt.text.empty?
              opts << [option_help(opt), opt.text]
            }
#           acc << [usage, cmd.text, opts]
            acc << ["Options", cmd.text, opts] # FIXME Fixture fox fix
          else
            acc << usage
          end
        else
          cmd.cmds.each { |subcmd|
            recursive_elements(acc, subcmd, levels: levels - 1, help: help)
          }
        end
      }
    end

    # Return command line usage string
    def self.command(cmd)
      (path_elements(cmd) + option_elements(cmd) + argument_elements(cmd)).compact.join(" ")
    end

    def self.path_elements(cmd)
      Algorithm.follow(cmd, :parent).map { |parent| parent.name }.reverse
    end

    def self.option_elements(cmd)
      elements = []
      collapsable_opts, other_opts = cmd.opts.partition { |opt| opt.shortname && !opt.argument? }

      if !collapsable_opts.empty?
        elements << "-" + collapsable_opts.map(&:shortname).join
      end

      elements + other_opts.map { |opt|
        if opt.shortname
          "-#{opt.shortname} #{opt.argument_name}" # We know opt has an argument
        elsif opt.argument?
          "--#{opt.longname}=#{opt.argument_name}"
        else
          "--#{opt.longname}"
        end
      }
    end

    def self.option_help(opt)
      result = opt.names.map { |name|
        if name.size == 1
          "-#{name}"
        else
          "--#{name}"
        end
      }.join(", ")
      if opt.argument?
        if opt.longname
          result += "=#{opt.argument_name}"
        else
          result += " #{opt.argument_name}"
        end
      end
      result
    end

    def self.subcommand_element(cmd)
      !cmd.cmds.empty? ? [cmd.cmds.map(&:name).join("|")] : []
    end

    def self.argument_elements(cmd)
      cmd.args
    end

    def self.help_element(cmd)
      text.map { |l| l.sub(/^\s*# /, "").rstrip }.join(" ")
    end
  end
end

