require "digital_ocean"

module Lita
  module Handlers
    class Digitalocean < Handler
      def self.default_config(config)
        config.client_id = nil
        config.api_key = nil
      end

      private

      def self.do_route(regexp, route_name, help)
        route(regexp, route_name, command: true, restrict_to: :digitalocean_admins, help: help)
      end

      public

      do_route /^do\s+ssh\s+keys?\s+list$/i, :ssh_keys_list, {
        t("help.ssh_keys.list_key") => t("help.ssh_keys.list_value")
      }

      do_route /^do\s+ssh\s+keys?\s+show\s+(\d+)$/i, :ssh_keys_show, {
        t("help.ssh_keys.show_key") => t("help.ssh_keys.show_value"),
      }

      def ssh_keys_list(response)
        do_response = do_call(response) do |client|
          client.ssh_keys.list
        end or return

        if do_response.ssh_keys.empty?
          response.reply(t("ssh_keys.list.empty"))
        else
          do_response.ssh_keys.each do |key|
            response.reply("#{key.id} (#{key.name})")
          end
        end
      end

      def ssh_keys_show(response)
        do_response = do_call(response) do |client|
          client.ssh_keys.show(response.matches[0][0])
        end or return

        key = do_response.ssh_key
        response.reply("#{key.id} (#{key.name}): #{key.ssh_pub_key}")
      end

      private

      def api_key
        config.api_key
      end

      def client
        @client ||= ::DigitalOcean::API.new(client_id: client_id, api_key: api_key)
      end

      def client_id
        config.client_id
      end

      def config
        Lita.config.handlers.digitalocean
      end

      def do_call(response)
        unless api_key && client_id
          response.reply(t("credentials_missing"))
          return
        end

        do_response = yield client

        if do_response.status != "OK"
          response.reply(t("error", message: do_response.message))
          return
        end

        do_response
      end
    end

    Lita.register_handler(Digitalocean)
  end
end
