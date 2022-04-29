# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'versionist')

describe ActionController::Base, type: :controller do
  controller do
    include Versionist::Controller::Migrations

    rescue_from Versionist::UnsupportedVersionError, with: -> { render json: { error: 'unsupported version' }, status: :bad_request }

    before_action :set_content_type

    def show
      render json: users.find { _1[:id].ends_with?(params[:id]) }
    end

    private

    def set_content_type
      response.headers['Content-Type'] = request.headers['Accept']
    end

    def users
      [
        { type: 'users', id: 'user_x7ydbo6fjd6pubeu', first_name: 'John', last_name: 'Smith' },
        { type: 'users', id: 'user_ogb9gjingwtvuj50', first_name: 'Jane', last_name: 'Doe' },
      ]
    end
  end

  before do
    Versionist.configure do |config|
      config.request_version_resolver = -> request {
        request.headers.fetch('Version') { Versionist.config.current_version }
      }

      config.current_version = '1.3'
      config.versions        = {
        '1.2' => [
          Class.new(Versionist::Migration) do
            description %(transforms a resource's type from plural to singular)

            migrate if: -> data { data in { type: } } do |data|
              data[:type] = data[:type].singularize
            end

            response if: -> res { res.request.params in { controller: 'anonymous', action: 'show' } } do |res|
              data = JSON.parse(res.body, symbolize_names: true)

              migrate!(data)

              res.body = JSON.generate(data)
            end
          end,
        ],
        '1.1' => [
          Class.new(Versionist::Migration) do
            description %(always assume an "application/json" content type for the response)

            response do |res|
              res.headers['Content-Type'] = 'application/json'
            end
          end,
          Class.new(Versionist::Migration) do
            description %(transforms a user's first and last name to combined name field)

            migrate if: -> data { data in { type: 'user' } } do |data|
              first_name = data.delete(:first_name)
              last_name  = data.delete(:last_name)

              data[:name] = "#{first_name} #{last_name}"
            end

            response if: -> res { res.request.params in { controller: 'anonymous', action: 'show' } } do |res|
              data = JSON.parse(res.body, symbolize_names: true)

              migrate!(data)

              res.body = JSON.generate(data)
            end
          end,
        ],
        '1.0' => [
          Class.new(Versionist::Migration) do
            description %(always assume an "application/json" content type for the request)

            request do |req|
              req.headers['Content-Type'] = 'application/json'
            end
          end,
          Class.new(Versionist::Migration) do
            description %(removes type prefixes from IDs)

            migrate if: -> data { data in { type:, id: } } do |data|
              data[:id] = data[:id].delete_prefix("#{data[:type]}_")
            end

            response if: -> res { res.request.params in { controller: 'anonymous', action: 'show' } } do |res|
              data = JSON.parse(res.body, symbolize_names: true)

              migrate!(data)

              res.body = JSON.generate(data)
            end
          end,
        ],
      }
    end
  end

  let(:request_content_type) { request.headers['Content-Type'] }
  let(:response_content_type) { response.headers['Content-Type'] }
  let(:response_body) { JSON.parse(response.body) }

  context 'when requesting the current version' do
    before do
      request.headers['Content-Type'] = 'application/vnd.test+json'
      request.headers['Accept']       = 'application/vnd.test+json'
    end

    it 'should not migrate the request' do
      get :show, params: { id: 'user_x7ydbo6fjd6pubeu' }

      expect(request_content_type).to eq 'application/vnd.test+json'
    end

    it 'should not migrate the response' do
      get :show, params: { id: 'user_x7ydbo6fjd6pubeu' }

      expect(response_content_type).to eq 'application/vnd.test+json'
      expect(response_body).to eq(
        'type' => 'users',
        'id' => 'user_x7ydbo6fjd6pubeu',
        'first_name' => 'John',
        'last_name' => 'Smith',
      )
    end
  end

  context 'when requesting version 1.2' do
    before do
      request.headers['Content-Type'] = 'application/vnd.test+json'
      request.headers['Accept']       = 'application/vnd.test+json'
      request.headers['Version']      = '1.2'
    end

    it 'should not migrate the request' do
      get :show, params: { id: 'user_ogb9gjingwtvuj50' }

      expect(request_content_type).to eq 'application/vnd.test+json'
    end

    it 'should migrate the response resource type' do
      get :show, params: { id: 'user_ogb9gjingwtvuj50' }

      expect(response_content_type).to eq 'application/vnd.test+json'
      expect(response_body).to eq(
        'type' => 'user',
        'id' => 'user_ogb9gjingwtvuj50',
        'first_name' => 'Jane',
        'last_name' => 'Doe',
      )
    end
  end

  context 'when requesting version 1.1' do
    before do
      request.headers['Content-Type'] = 'application/vnd.test+json'
      request.headers['Accept']       = 'application/vnd.test+json'
      request.headers['Version']      = '1.1'
    end

    it 'should not migrate the request' do
      get :show, params: { id: 'user_x7ydbo6fjd6pubeu' }

      expect(request_content_type).to eq 'application/vnd.test+json'
    end

    it 'should migrate the response content type and user name' do
      get :show, params: { id: 'user_x7ydbo6fjd6pubeu' }

      expect(response_content_type).to eq 'application/json'
      expect(response_body).to eq(
        'type' => 'user',
        'id' => 'user_x7ydbo6fjd6pubeu',
        'name' => 'John Smith',
      )
    end
  end

  context 'when requesting version 1.0' do
    before do
      request.headers['Content-Type'] = 'application/vnd.test+json'
      request.headers['Accept']       = 'application/vnd.test+json'
      request.headers['Version']      = '1.0'
    end

    it 'should migrate the request content type' do
      get :show, params: { id: 'ogb9gjingwtvuj50' }

      expect(request_content_type).to eq 'application/json'
    end

    it 'should migrate the response resource IDs' do
      get :show, params: { id: 'ogb9gjingwtvuj50' }

      data = response_body

      expect(response_content_type).to eq 'application/json'
      expect(response_body).to eq(
        'type' => 'user',
        'id' => 'ogb9gjingwtvuj50',
        'name' => 'Jane Doe',
      )
    end
  end

  context 'when requesting an unsupported version' do
    before { request.headers['Version'] = '2.0' }

    it 'should respond with an error' do
      get :show, params: { id: 'ogb9gjingwtvuj50' }

      expect(response).to have_http_status :bad_request
      expect(response_body).to eq(
        'error' => 'unsupported version',
      )
    end
  end

  context 'when using a one-off migrator' do
    let(:data) { { type: 'users', id: 'user_x7ydbo6fjd6pubeu', first_name: 'John', last_name: 'Smith' } }

    it 'should migrate between versions' do
      migrator = Versionist::Migrator.new(from: '1.3', to: '1.1')
      migrator.migrate!(data:)

      expect(data).to eq(
        type: 'user',
        id: 'user_x7ydbo6fjd6pubeu',
        name: 'John Smith',
      )
    end
  end

  context 'when using an invalid config' do
    [
      42,
      4.2,
      -> {},
      {},
      [],
      true,
      false,
      nil,
    ].each do |migration|
      it "should raise error for invalid migration type: #{migration.class.name}" do
        Versionist.configure do |config|
          config.current_version = '1.1'
          config.versions        = {
            '1.0' => [migration],
          }
        end

        migrator = Versionist::Migrator.new(from: '1.1', to: '1.0')

        expect { migrator.migrate!(data: {}) }.to raise_error Versionist::UnsupportedMigrationError
      end
    end
  end

  context 'when using a valid config' do
    before do
      stub_const('TestMigration', Class.new(Versionist::Migration))
    end

    [
      :test_migration,
      'test_migration',
    ].each do |migration|
      it "should not raise error for valid migration type: #{migration.class.name}" do
        Versionist.configure do |config|
          config.current_version = '1.1'
          config.versions        = {
            '1.0' => [migration],
          }
        end

        migrator = Versionist::Migrator.new(from: '1.1', to: '1.0')

        expect { migrator.migrate!(data: {}) }.to_not raise_error
      end
    end

    # NOTE(ezekg) Have to run this separately so we aren't hit with an
    #             uninitialized constant error
    it "should not raise error for valid migration type: constant" do
      Versionist.configure do |config|
        config.current_version = '1.1'
        config.versions        = {
          '1.0' => [TestMigration],
        }
      end

      migrator = Versionist::Migrator.new(from: '1.1', to: '1.0')

      expect { migrator.migrate!(data: {}) }.to_not raise_error
    end

    [
      [:semver, '1.0', '2.0'],
      [:date, Date.yesterday.iso8601, Date.today.iso8601],
      [:integer, 1, 2],
      [:float, 1.0, 2.0],
      [:string, 'a', 'b'],
    ].each do |(version_format, prev_version, version)|
      it "should not raise error for valid version format: #{version_format}" do
        Versionist.configure do |config|
          config.version_format  = version_format
          config.current_version = version
          config.versions        = {
            prev_version => [:test_migration],
          }
        end

        expect { Versionist::Migrator.new(from: version, to: prev_version).migrate!(data: {}) }
          .to_not raise_error
      end
    end

    [
      [:class, Class.new, Class.new],
      [:hash, { v: 1 }, { v: 2 }],
      [:array, [1], [2]],
      [:symbol, :a, :b],
    ].each do |(version_format, prev_version, version)|
      it "should raise error for invalid version format: #{version_format}" do
        Versionist.configure do |config|
          config.version_format  = version_format
          config.current_version = version
          config.versions        = {
            prev_version => [:test_migration],
          }
        end

        expect { Versionist::Migrator.new(from: version, to: prev_version).migrate!(data: {}) }
          .to raise_error Versionist::InvalidVersionFormatError
      end
    end
  end
end
