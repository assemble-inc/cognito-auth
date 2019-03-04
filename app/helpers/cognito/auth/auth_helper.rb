module Cognito
  module Auth
    module AuthHelper
      include Cognito::Auth::Helpers

      def with_cognito_catch
        yield
      rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
        flash[:danger] = t(error.class.to_s.demodulize.underscore, scope: 'cognito-auth')
        redirect_to cognito_auth.login_path
        return false
      end

      def current_user
        with_cognito_catch { @current_user ||= Cognito::Auth.current_user }
      end

      def validate!
        with_cognito_catch { Cognito::Auth.validate! }
      end

      def logged_in?
        Cognito::Auth.logged_in?
      end

      def authenticate(auth_parameters)
        with_cognito_catch {
          Cognito::Auth.authenticate(auth_parameters)
          if current_user.present?
            redirect_to main_app.root_path
            return true
          else
            # have a challenge handler at that specific url
            flash[:warning] = t(Cognito::Auth.session[:challenge_name].downcase, scope: 'cognito-auth')
            redirect_to "#{cognito_auth.root_path}#{Cognito::Auth.session[:challenge_name].gsub('_','-').downcase}"
            return false
          end
        }
      end

      def respond_to_auth_challenge(challenge_responses)
        with_cognito_catch {
          Cognito::Auth.respond_to_auth_challenge(challenge_responses)
          if current_user.present?
            redirect_to main_app.root_path
            return true
          else
            # have a challenge handler at that specific url
            redirect_to "#{cognito_auth.root_path}#{Cognito::Auth.session[:challenge_name].gsub('_','-').downcase}"
            return false
          end
        }
      end

      def log_out
        with_cognito_catch {
          Cognito::Auth.log_out
          redirect_to login_path
          return true
        }
      end

      def log_in(username,password)
        authenticate(USERNAME:username, PASSWORD:password)
      end

      def replace_temporary_password(newpass)
        respond_to_auth_challenge(USERNAME:Cognito::Auth.session[:username], NEW_PASSWORD:newpass)
      end

    end
  end
end
