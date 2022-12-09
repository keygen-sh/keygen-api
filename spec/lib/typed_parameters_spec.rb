# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'typed_parameters'

describe TypedParameters do
  let :schema do
    TypedParameters::Schema.new type: :hash do
      param :foo, type: :hash do
        param :bar, type: :array do
          items type: :hash do
            param :baz, type: :integer
          end
        end
      end
    end
  end

  describe TypedParameters::Schema do
    %i[
      in
    ].each do |option|
      it "should not raise on valid :inclusion option: #{option}" do
        expect { TypedParameters::Schema.new(type: :string, inclusion: { option => %w[foo] }) }.to_not raise_error
      end
    end

    it 'should raise on invalid :inclusion options' do
      expect { TypedParameters::Schema.new(type: :string, inclusion: { invalid: %w[foo] }) }
        .to raise_error ArgumentError
    end

    it 'should raise on missing :inclusion options' do
      expect { TypedParameters::Schema.new(type: :string, inclusion: {}) }
        .to raise_error ArgumentError
    end

    %i[
      in
    ].each do |option|
      it "should not raise on valid :exclusion option: #{option}" do
        expect { TypedParameters::Schema.new(type: :string, exclusion: { option => %w[bar] }) }.to_not raise_error
      end
    end

    it 'should raise on invalid :exclusion options' do
      expect { TypedParameters::Schema.new(type: :string, exclusion: { invalid: %w[bar] }) }
        .to raise_error ArgumentError
    end

    it 'should raise on missing :exclusion options' do
      expect { TypedParameters::Schema.new(type: :string, exclusion: {}) }
        .to raise_error ArgumentError
    end

    %i[
      with
      without
    ].each do |option|
      it "should not raise on valid :format option: #{option}" do
        expect { TypedParameters::Schema.new(type: :string, format: { option => /baz/ }) }.to_not raise_error
      end
    end

    it 'should raise on multiple :format options' do
      expect { TypedParameters::Schema.new(type: :string, format: { with: /baz/, without: /qux/ }) }
        .to raise_error ArgumentError
    end

    it 'should raise on invalid :format options' do
      expect { TypedParameters::Schema.new(type: :string, format: { invalid: /baz/ }) }
        .to raise_error ArgumentError
    end

    it 'should raise on missing :format options' do
      expect { TypedParameters::Schema.new(type: :string, format: {}) }
        .to raise_error ArgumentError
    end

    {
      minimum: 1,
      maximum: 1,
      within: 1..3,
      in: [1, 2, 3],
      is: 1,
    }.each do |option, length|
      it "should not raise on valid :length option: #{option}" do
        expect { TypedParameters::Schema.new(type: :string, length: { option => length }) }.to_not raise_error
      end
    end

    it 'should raise on multiple :length options' do
      expect { TypedParameters::Schema.new(type: :string, length: { in: 1..3, maximum: 42 }) }
        .to raise_error ArgumentError
    end

    it 'should raise on invalid :length options' do
      expect { TypedParameters::Schema.new(type: :string, length: { invalid: /bar/ }) }
        .to raise_error ArgumentError
    end

    it 'should raise on missing :length options' do
      expect { TypedParameters::Schema.new(type: :string, length: {}) }
        .to raise_error ArgumentError
    end

    it 'should have a correct path' do
      grandchild = schema.children[:foo]
                         .children[:bar]
                         .children[0]
                         .children[:baz]

      expect(grandchild.path.to_json_pointer).to eq '/foo/bar/0/baz'
    end

    it 'should have correct array keys' do
      grandchild = schema.children[:foo]
                         .children[:bar]

      expect(grandchild.keys).to eq [0]
    end

    it 'should have correct hash keys' do
      grandchild = schema.children[:foo]

      expect(grandchild.keys).to eq %i[bar]
    end
  end

  describe TypedParameters::Types do
    describe '.register' do
      after { TypedParameters::Types.unregister(:test) }

      it 'should register a type' do
        type = TypedParameters::Types.register(:test,
          match: -> v { v == :test },
          coerce: -> v { :test },
        )

        expect(TypedParameters::Types.types[:test]).to eq type
      end

      it 'should not register a duplicate type' do
        type = TypedParameters::Types.register(:test,
          match: -> v { v == :test },
        )

        expect { TypedParameters::Types.register(:test, match: -> v { v == :test }) }
          .to raise_error TypedParameters::DuplicateTypeError
      end
    end

    describe '.unregister' do
      it 'should unregister a type' do
        TypedParameters::Types.register(:test, match: -> v { v == :test })
        TypedParameters::Types.unregister(:test)

        expect(TypedParameters::Types.types[:test]).to be_nil
      end
    end

    describe '.for' do
      it 'should fetch a type by value' do
        type = TypedParameters::Types.for(1)

        expect(type.type).to eq :integer
      end
    end

    describe '.[]' do
      it 'should fetch a type by key' do
        type = TypedParameters::Types[:string]

        expect(type.type).to eq :string
      end
    end

    describe :boolean do
      let(:type) { TypedParameters.types[:boolean] }

      it 'should match' do
        expect(type.match?(true)).to be true
        expect(type.match?(false)).to be true
      end

      it 'should not match' do
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :string do
      let(:type) { TypedParameters.types[:string] }

      it 'should match' do
        expect(type.match?('foo')).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :symbol do
      let(:type) { TypedParameters.types[:symbol] }

      it 'should match' do
        expect(type.match?(:foo)).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :integer do
      let(:type) { TypedParameters.types[:integer] }

      it 'should match' do
        expect(type.match?(1)).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?(1.0)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
      end
    end

    describe :float do
      let(:type) { TypedParameters.types[:float] }

      it 'should match' do
        expect(type.match?(2.0)).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :number do
      let(:type) { TypedParameters.types[:number] }

      it 'should match' do
        expect(type.match?(2.0)).to be true
        expect(type.match?(1)).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
      end
    end

    describe :array do
      let(:type) { TypedParameters.types[:array] }

      it 'should match' do
        expect(type.match?([])).to be true
        expect(type.match?([1])).to be true
        expect(type.match?([''])).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?({})).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :hash do
      let(:type) { TypedParameters.types[:hash] }

      it 'should match' do
        expect(type.match?({})).to be true
        expect(type.match?({ foo: {} })).to be true
        expect(type.match?({ bar: 1 })).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?(nil)).to be false
        expect(type.match?([])).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end

    describe :nil do
      let(:type) { TypedParameters.types[:nil] }

      it 'should match' do
        expect(type.match?(nil)).to be true
      end

      it 'should not match' do
        expect(type.match?(true)).to be false
        expect(type.match?({})).to be false
        expect(type.match?([])).to be false
        expect(type.match?('')).to be false
        expect(type.match?(1)).to be false
      end
    end
  end

  describe TypedParameters::Parameterizer do
    it 'should parameterize array' do
      schema = TypedParameters::Schema.new(type: :array) { items(type: :hash) { param(:key, type: :symbol) } }
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = [{ key: :foo }, { key: :bar }, { key: :baz }]

      expect(paramz.call(value: params)).to satisfy { |res|
        res in TypedParameters::Parameter(
          value: [
            TypedParameters::Parameter(
              value: {
                key: TypedParameters::Parameter(value: :foo),
              },
            ),
            TypedParameters::Parameter(
              value: {
                key: TypedParameters::Parameter(value: :bar),
              },
            ),
            TypedParameters::Parameter(
              value: {
                key: TypedParameters::Parameter(value: :baz),
              },
            ),
          ],
        )
      }
    end

    it 'should parameterize hash' do
      schema = TypedParameters::Schema.new(type: :hash) { param(:foo, type: :hash) { param(:bar, type: :symbol) } }
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = { foo: { bar: :baz } }

      expect(paramz.call(value: params)).to satisfy { |res|
        res in TypedParameters::Parameter(
          value: {
            foo: TypedParameters::Parameter(
              value: {
                bar: TypedParameters::Parameter(value: :baz),
              },
            ),
          },
        )
      }
    end

    it 'should parameterize scalar' do
      schema = TypedParameters::Schema.new(type: :symbol)
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = :foo

      expect(paramz.call(value: params)).to satisfy { |res|
        res in TypedParameters::Parameter(value: :foo)
      }
    end

    it 'should not raise on unbounded array' do
      schema = TypedParameters::Schema.new(type: :array) { items type: :string }
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = %w[
        foo
        bar
        baz
      ]

      expect { paramz.call(value: params) }.to_not raise_error
    end

    it 'should not raise on bounded array' do
      schema = TypedParameters::Schema.new(type: :array) { item type: :string; item type: :string }
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = %w[
        foo
        bar
      ]

      expect { paramz.call(value: params) }.to_not raise_error
    end

    it 'should raise on bounded array' do
      schema = TypedParameters::Schema.new(type: :array) { item type: :string; item type: :string }
      paramz = TypedParameters::Parameterizer.new(schema:)
      params = %w[
        foo
        bar
        baz
      ]

      expect { paramz.call(value: params) }.to raise_error TypedParameters::UnpermittedParameterError
    end

    context 'with non-strict schema' do
      let(:schema) { TypedParameters::Schema.new(strict: false) { param :foo, type: :string } }

      it 'should not raise on unpermitted params' do
        paramz = TypedParameters::Parameterizer.new(schema:)
        params = { bar: 'baz' }

        expect { paramz.call(value: params) }.to_not raise_error
      end

      it 'should delete unpermitted params' do
        paramz = TypedParameters::Parameterizer.new(schema:)
        params = { bar: 'baz' }

        expect(paramz.call(value: params)).to_not have_key :bar
      end
    end

    context 'with strict schema' do
      let(:schema) { TypedParameters::Schema.new(strict: true) { param :foo, type: :string } }

      it 'should raise on unpermitted params' do
        paramz = TypedParameters::Parameterizer.new(schema:)
        params = { bar: 'baz' }

        expect { paramz.call(value: params) }.to raise_error TypedParameters::UnpermittedParameterError
      end
    end
  end

  describe TypedParameters::Formatters do
    describe '.register' do
      after { TypedParameters::Formatters.unregister(:test) }

      it 'should register a format' do
        format = TypedParameters::Formatters.register(:test,
          transform: -> k, v { [k, v] },
        )

        expect(TypedParameters::Formatters.formats[:test]).to eq format
      end

      it 'should not register a duplicate format' do
        format = TypedParameters::Formatters.register(:test,
          transform: -> k, v { [k, v] },
        )

        expect { TypedParameters::Formatters.register(:test, transform: -> k, v { [k, v] },) }
          .to raise_error TypedParameters::DuplicateFormatterError
      end
    end

    describe '.unregister' do
      it 'should unregister a format' do
        TypedParameters::Formatters.register(:test, transform: -> k, v { [k, v] },)
        TypedParameters::Formatters.unregister(:test)

        expect(TypedParameters::Formatters.formats[:test]).to be_nil
      end
    end

    describe '.[]' do
      it 'should fetch a format by key' do
        format = TypedParameters::Formatters[:jsonapi]

        expect(format.format).to eq :jsonapi
      end
    end
  end

  describe TypedParameters::Formatters::JSONAPI do
    let :schema do
      TypedParameters::Schema.new(type: :hash) do
        format :jsonapi

        param :meta, type: :hash, allow_non_scalars: true, optional: true
        param :data, type: :hash do
          param :type, type: :string, inclusion: { in: %w[users user] }
          param :id, type: :string
          param :attributes, type: :hash do
            param :first_name, type: :string, optional: true
            param :last_name, type: :string, optional: true
            param :email, type: :string, format: { with: /@/ }
            param :password, type: :string
          end
          param :relationships, type: :hash do
            param :note, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: { in: %w[notes note] }
                param :id, type: :string
                param :attributes, type: :hash, optional: true do
                  param :content, type: :string, length: { minimum: 80 }
                end
              end
            end
            param :team, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: { in: %w[teams team] }
                param :id, type: :string
              end
            end
            param :posts, type: :hash do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: { in: %w[posts post] }
                  param :id, type: :string
                  param :attributes, type: :hash, optional: true do
                    param :title, type: :string, length: { maximum: 80 }
                    param :content, type: :string, length: { minimum: 80 }, optional: true
                  end
                end
              end
            end
            param :friends, type: :hash do
              param :data, type: :array do
                items type: :hash do
                  param :type, type: :string, inclusion: { in: %w[users user] }
                  param :id, type: :string
                end
              end
            end
          end
        end
      end
    end

    let :data do
      {
        type: 'users',
        id: SecureRandom.base58,
        attributes: {
          email: 'foo@keygen.example',
          password: SecureRandom.hex,
        },
        relationships: {
          note: {
            data: { type: 'notes', id: SecureRandom.base58, attributes: { content: 'Test' } },
          },
          team: {
            data: { type: 'teams', id: SecureRandom.base58 },
          },
          posts: {
            data: [
              { type: 'posts', id: SecureRandom.base58 },
              { type: 'posts', id: SecureRandom.base58, attributes: { title: 'Testing! 1, 2, 3!' } },
              { type: 'posts', id: SecureRandom.base58 },
              { type: 'posts', id: SecureRandom.base58 },
            ],
          },
          friends: {
            data: [
              { type: 'users', id: SecureRandom.base58 },
              { type: 'users', id: SecureRandom.base58 },
            ],
          },
        },
      }
    end

    let :meta do
      {
        key: {
          key: 'value',
        },
      }
    end

    it 'should format params' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { meta:, data: })

      expect(params.unwrap).to eq(
        id: data[:id],
        email: data[:attributes][:email],
        password: data[:attributes][:password],
        note_attributes: {
          id: data[:relationships][:note][:data][:id],
          content: data[:relationships][:note][:data][:attributes][:content],
        },
        team_id: data[:relationships][:team][:data][:id],
        posts_attributes: [
          { id: data[:relationships][:posts][:data][0][:id] },
          { id: data[:relationships][:posts][:data][1][:id], title: data[:relationships][:posts][:data][1][:attributes][:title] },
          { id: data[:relationships][:posts][:data][2][:id] },
          { id: data[:relationships][:posts][:data][3][:id] },
        ],
        friend_ids: [
          data[:relationships][:friends][:data][0][:id],
          data[:relationships][:friends][:data][1][:id],
        ],
      )
    end

    it 'should not format params' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { meta:, data: })

      expect(params.unwrap(formatter: nil)).to eq(
        meta:,
        data:,
      )
    end
  end

  describe TypedParameters::Formatters::Rails do
    let :controller do
      Class.new(ActionController::Base) { @controller_name = 'users' }
    end

    let :schema do
      TypedParameters::Schema.new(type: :hash) do
        format :rails

        param :first_name, type: :string, optional: true
        param :last_name, type: :string, optional: true
        param :email, type: :string, format: { with: /@/ }
        param :password, type: :string
      end
    end

    let :user do
      {
        first_name: 'Foo',
        last_name: 'Bar',
        email: 'foo@keygen.example',
        password: SecureRandom.hex,
      }
    end

    it 'should format params' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: user)

      expect(params.unwrap(controller:)).to eq(user:)
    end

    it 'should format params' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: user)

      expect(params.unwrap(formatter: nil)).to eq(user)
    end
  end

  describe TypedParameters::Transforms::KeyCasing do
    let(:transform) { TypedParameters::Transforms::KeyCasing.new }
    let(:casing)    { nil }

    before { TypedParameters.config.key_transform = casing }
    after  { TypedParameters.config.key_transform = nil }

    context 'with no key transform' do
      %w[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should not transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => 'baz' })

          expect(k).to eq key
          expect(v).to eq key => 'baz'
        end
      end

      %i[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should mot transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => :baz })

          expect(k).to eq key
          expect(v).to eq key => :baz
        end
      end
    end

    context 'with :underscore key transform' do
      let(:casing) { :underscore }

      %w[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => 'baz' })

          expect(k).to eq 'foo_bar'
          expect(v).to eq k => 'baz'
        end
      end

      %i[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => :baz })

          expect(k).to eq :foo_bar
          expect(v).to eq k => :baz
        end
      end
    end

    context 'with :camel key transform' do
      let(:casing) { :camel }

      %w[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => 'baz' })

          expect(k).to eq 'FooBar'
          expect(v).to eq k => 'baz'
        end
      end

      %i[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => :baz })

          expect(k).to eq :FooBar
          expect(v).to eq k => :baz
        end
      end
    end

    context 'with :lower_camel key transform' do
      let(:casing) { :lower_camel }

      %w[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => 'baz' })

          expect(k).to eq 'fooBar'
          expect(v).to eq k => 'baz'
        end
      end

      %i[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => :baz })

          expect(k).to eq :fooBar
          expect(v).to eq k => :baz
        end
      end
    end

    context 'with :dash key transform' do
      let(:casing) { :dash }

      %w[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => 'baz' })

          expect(k).to eq 'foo-bar'
          expect(v).to eq k => 'baz'
        end
      end

      %i[
        foo_bar
        foo-bar
        FooBar
        fooBar
      ].each do |key|
        it "should transform key: #{key.inspect}" do
          k, v = transform.call(key, { key => :baz })

          expect(k).to eq :'foo-bar'
          expect(v).to eq k => :baz
        end
      end
    end
  end

  describe TypedParameters::Transforms::NilifyBlanks do
    let(:transform) { TypedParameters::Transforms::NilifyBlanks.new }

    [
      string: '',
      array: [],
      hash: {},
    ].each do |key, value|
      it "should transform a blank #{key} to nil" do
        k, v = transform.call(key, value)

        expect(k).to eq key
        expect(v).to be nil
      end
    end

    [
      string: 'foo',
      array: [:foo],
      hash: { foo: :bar },
    ].each do |key, value|
      it "should not transform a present #{key} to nil" do
        k, v = transform.call(key, value)

        expect(k).to eq key
        expect(v).to be value
      end
    end
  end

  describe TypedParameters::Transforms::Noop do
    let(:transform) { TypedParameters::Transforms::Noop.new }

    it 'should be a noop' do
      k, v = transform.call('foo', 'bar')

      expect(k).to be nil
      expect(v).to be nil
    end
  end

  describe TypedParameters::Validations::Exclusion do
    let(:validation) { TypedParameters::Validations::Exclusion.new(options) }
    let(:options)    { nil }

    context 'with in: option' do
      let(:options) {{ in: %w[a b c] }}

      it 'should succeed' do
        expect(validation.call('d')).to be true
      end

      it 'should fail' do
        expect(validation.call('a')).to be false
      end
    end
  end

  describe TypedParameters::Validations::Format do
    let(:validation) { TypedParameters::Validations::Format.new(options) }
    let(:options)    { nil }

    context 'with without: option' do
      let(:options) {{ without: /foo/ }}

      it 'should succeed' do
        expect(validation.call('bar')).to be true
      end

      it 'should fail' do
        expect(validation.call('foo')).to be false
      end
    end

    context 'with with: option' do
      let(:options) {{ with: /foo/ }}

      it 'should succeed' do
        expect(validation.call('foo')).to be true
      end

      it 'should fail' do
        expect(validation.call('bar')).to be false
      end
    end
  end

  describe TypedParameters::Validations::Inclusion do
    let(:validation) { TypedParameters::Validations::Inclusion.new(options) }
    let(:options)    { nil }

    context 'with in: option' do
      let(:options) {{ in: %w[a b c] }}

      it 'should succeed' do
        expect(validation.call('a')).to be true
      end

      it 'should fail' do
        expect(validation.call('d')).to be false
      end
    end
  end

  describe TypedParameters::Validations::Length do
    let(:validation) { TypedParameters::Validations::Length.new(options) }
    let(:options)    { nil }

    context 'with minimum: option' do
      let(:options) {{ minimum: 5 }}

      it 'should succeed' do
        expect(validation.call('foobar')).to be true
      end

      it 'should fail' do
        expect(validation.call('foo')).to be false
      end
    end

    context 'with maximum: option' do
      let(:options) {{ maximum: 5 }}

      it 'should succeed' do
        expect(validation.call('foo')).to be true
      end

      it 'should fail' do
        expect(validation.call('foobarbaz')).to be false
      end
    end

    context 'with within: option' do
      let(:options) {{ within: 1..3 }}

      it 'should succeed' do
        expect(validation.call('foo')).to be true
      end

      it 'should fail' do
        expect(validation.call('foobar')).to be false
      end
    end

    context 'with in: option' do
      let(:options) {{ in: 1...6 }}

      it 'should succeed' do
        expect(validation.call('foo')).to be true
      end

      it 'should fail' do
        expect(validation.call('foobar')).to be false
      end
    end

    context 'with is: option' do
      let(:options) {{ is: 42 }}

      it 'should succeed' do
        expect(validation.call('a'*42)).to be true
      end

      it 'should fail' do
        expect(validation.call('a'*7)).to be false
      end
    end
  end

  describe TypedParameters::Path do
    let(:path)   { TypedParameters::Path.new(:foo, :bar_baz, 42, :qux) }
    let(:casing) { nil }

    before { TypedParameters.config.path_transform = casing }
    after  { TypedParameters.config.path_transform = nil }

    it 'should support JSON pointer paths' do
      expect(path.to_json_pointer).to eq '/foo/bar_baz/42/qux'
    end

    it 'should support dot notation paths' do
      expect(path.to_dot_notation).to eq 'foo.bar_baz.42.qux'
    end

    context 'with no path transform' do
      it 'should not transform path' do
        expect(path.to_s).to eq 'foo.bar_baz[42].qux'
      end
    end

    context 'with :underscore path transform' do
      let(:casing) { :underscore }

      it 'should transform path' do
        expect(path.to_s).to eq 'foo.bar_baz[42].qux'
      end
    end

    context 'with :camel path transform' do
      let(:casing) { :camel }

      it 'should transform path' do
        expect(path.to_s).to eq 'Foo.BarBaz[42].Qux'
      end
    end

    context 'with :lower_camel path transform' do
      let(:casing) { :lower_camel }

      it 'should transform path' do
        expect(path.to_s).to eq 'foo.barBaz[42].qux'
      end
    end

    context 'with :dash path transform' do
      let(:casing) { :dash }

      it 'should transform path' do
        expect(path.to_s).to eq 'foo.bar-baz[42].qux'
      end
    end
  end

  describe TypedParameters::Parameter do
    it 'should delegate missing methods to value' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })
      orig   = params.dup

      expect { params.stringify_keys! }.to_not raise_error
      expect { params.fetch(:foo) }.to raise_error KeyError
      expect { params.fetch('foo') }.to_not raise_error
      expect { params.merge!(qux: 2) }.to_not raise_error
      expect { params.fetch(:qux) }.to_not raise_error
      expect { params.reject! { _1 == :qux } }.to_not raise_error
      expect { params.fetch(:qux) }.to raise_error KeyError
      expect { params.symbolize_keys! }.to_not raise_error

      expect(params.value).to eq orig.value
    end

    it 'should have a correct path' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }] } })

      expect(params[:foo][:bar][0][:baz].path.to_json_pointer).to eq '/foo/bar/0/baz'
      expect(params[:foo][:bar][1][:baz].path.to_json_pointer).to eq '/foo/bar/1/baz'
    end

    context 'with array schema' do
      let(:schema) { TypedParameters::Schema.new(type: :array) { items type: :string } }

      it 'should have correct keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: %w[a b c])

        expect(params.keys).to eq [0, 1, 2]
      end

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: [])

        expect(params.keys).to eq []
      end
    end

    context 'with hash schema' do
      let(:schema) { TypedParameters::Schema.new(type: :hash) { params :a, :b, :c, type: :string } }

      it 'should have correct keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: 3 })

        expect(params.keys).to eq %i[a b c]
      end

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: {})

        expect(params.keys).to eq []
      end
    end

    context 'with other schema' do
      let(:schema) { TypedParameters::Schema.new(type: :integer) }

      it 'should have no keys' do
        params = TypedParameters::Parameterizer.new(schema:).call(value: 1)

        expect(params.keys).to eq []
      end
    end
  end

  describe TypedParameters::Mapper do
    let :schema do
      TypedParameters::Schema.new type: :hash do
        param :foo, type: :hash do
          param :bar, type: :array do
            items type: :hash do
              param :baz, type: :integer
            end
          end
          param :qux, type: :array do
            items type: :hash do
              param :quux, type: :integer
            end
          end
        end
      end
    end

    it 'should use a depth-first algorithm' do
      params = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }, { baz: 1 }, { baz: 2 }], qux: [{ quux: 0 }, { quux: 1 }, { quux: 2 }] } })
      order  = []

      rule = Class.new(TypedParameters::Mapper) do
        define_method :call do |params|
          depth_first_map(params) { order << _1.path.to_json_pointer }
        end
      end

      rule.new(schema:).call(params)

      expect(order).to eq [
        '/foo/bar/0/baz',
        '/foo/bar/0',
        '/foo/bar/1/baz',
        '/foo/bar/1',
        '/foo/bar/2/baz',
        '/foo/bar/2',
        '/foo/bar',
        '/foo/qux/0/quux',
        '/foo/qux/0',
        '/foo/qux/1/quux',
        '/foo/qux/1',
        '/foo/qux/2/quux',
        '/foo/qux/2',
        '/foo/qux',
        '/foo',
        '/',
      ]
    end
  end

  describe TypedParameters::Validator do
    it 'should not raise on type match' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 0 }] } })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on type mismatch' do
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: { bar: [{ baz: 'qux' }] } })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on missing optional root' do
      schema    = TypedParameters::Schema.new(type: :hash, optional: true)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: nil)
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on missing required root' do
      schema    = TypedParameters::Schema.new(type: :hash, optional: false)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: nil)
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on missing optional param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, optional: true }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: {})
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on missing required param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, optional: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: {})
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should skip :validate validation on nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: true, validate: -> v { v == 1 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on nil param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_nil: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: nil })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on false param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :boolean, allow_blank: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: false })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should not raise on 0 param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, allow_blank: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 0 })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should not raise on 0.0 param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :float, allow_blank: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 0.0 })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should not raise on blank param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should skip :length validation on blank param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: true, length: { is: 3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on blank param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on :inclusion param validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'b' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on :inclusion param validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: { in: %w[a b c] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on :exclusion param validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on :exclusion param validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: { in: %w[a b c] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'c' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :with format validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :with format validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { with: /bar/ } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'baz' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :without format validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'z' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :without format validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, format: { without: /^a/ } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'a' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :minimum length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :minimum length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { minimum: 3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :maximum length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :maximum length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { maximum: 3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :within length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :within length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { within: 1..3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :in length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :in length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { in: 1..3 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b c d] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :is length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a b] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :is length validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :array, length: { is: 2 } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: %w[a] })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :validate validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'ok' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on param :validate validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'ko' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on hash of scalar values' do
      schema    = TypedParameters::Schema.new(type: :hash)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: 3 })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on hash of non-scalar values' do
      schema    = TypedParameters::Schema.new(type: :hash)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on hash of non-scalar values' do
      schema    = TypedParameters::Schema.new(type: :hash, allow_non_scalars: true)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { a: 1, b: 2, c: { d: 3 } })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should not raise on array of scalar values' do
      schema    = TypedParameters::Schema.new(type: :array)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, 3])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on array of non-scalar values' do
      schema    = TypedParameters::Schema.new(type: :array)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, [3]])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on array of non-scalar values' do
      schema    = TypedParameters::Schema.new(type: :array, allow_non_scalars: true)
      params    = TypedParameters::Parameterizer.new(schema:).call(value: [1, 2, [3]])
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end
  end

  describe TypedParameters::Coercer do
    let :schema do
      TypedParameters::Schema.new type: :hash do
        param :boolean, type: :boolean, coerce: true
        param :string, type: :string, coerce: true
        param :integer, type: :integer, coerce: true
        param :float, type: :float, coerce: true
        param :date, type: :date, coerce: true
        param :time, type: :time, coerce: true
        param :nil, type: :nil, coerce: true
        param :hash, type: :hash, coerce: true
        param :array, type: :array, coerce: true
      end
    end

    it 'should coerce true' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { boolean: 1 })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:boolean].value).to be true
    end

    it 'should coerce false' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { boolean: 0 })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:boolean].value).to be false
    end

    it 'should coerce string' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { string: 1 })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:string].value).to eq '1'
    end

    it 'should coerce integer' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { integer: '1' })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:integer].value).to eq 1
    end

    it 'should coerce float' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { float: 1 })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:float].value).to eq 1.0
    end

    it 'should coerce date' do
      now = Date.today

      params  = TypedParameters::Parameterizer.new(schema:).call(value: { date: now.to_s })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:date].value).to eq now
    end

    it 'should coerce time' do
      now = Time.now

      params  = TypedParameters::Parameterizer.new(schema:).call(value: { time: now.strftime('%H:%M:%S.%6N') })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:time].value).to eq now
    end

    it 'should coerce nil' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { nil: 1 })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:nil].value).to be nil
    end

    it 'should coerce array' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { array: '1,2,3' })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:array].value).to eq %w[1 2 3]
    end

    it 'should coerce hash' do
      params  = TypedParameters::Parameterizer.new(schema:).call(value: { hash: [[:foo, 1]] })
      coercer = TypedParameters::Coercer.new(schema:)

      coercer.call(params)

      expect(params[:hash].value).to eq({ foo: 1 })
    end
  end

  describe TypedParameters::Transformer do
    it 'should traverse params depth-first' do
      schema = TypedParameters::Schema.new(type: :hash) do
        param :parent, type: :hash, transform: -> k, v { [:a, v[:b].to_i] } do
          param :child, type: :hash, transform: -> k, v { [:b, v[:c].to_i] } do
            param :grandchild, type: :hash, transform: -> k, v { [:c, v[:d].to_i] } do
              param :value, type: :integer, transform: -> k, v { [:d, v.to_i]}
            end
          end
        end
      end

      data        = { parent: { child: { grandchild: { value: 42 } } } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: data)
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:a].value).to eq 42
    end

    it 'should not transform the param when omitted' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo].key).to eq :foo
      expect(params[:foo].value).to eq 1
    end

    it 'should not transform the param with noop' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [k, v] } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo].key).to eq :foo
      expect(params[:foo].value).to eq 1
    end

    it 'should transform array params' do
      schema      = TypedParameters::Schema.new(type: :array) { item type: :integer, transform: -> k, v { [1, v + 1] } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: [1] )
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[0]).to be nil
      expect(params[1].key).to eq 1
      expect(params[1].value).to eq 2
    end

    it 'should transform hash params' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [:bar, v + 1] } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:bar].key).to eq :bar
      expect(params[:bar].value).to eq 2
    end

    it 'should delete the param' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [] } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to be nil
    end

    it 'should not transform blank param to nil' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, nilify_blanks: false }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo].value).to eq ''
    end

    it 'should transform blank param to nil' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, nilify_blanks: true }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo].value).to be nil
    end

    it 'should not remove noop param' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, noop: false }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to_not be nil
    end

    it 'should remove noop param' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, noop: true }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo]).to be nil
    end
  end

  describe TypedParameters::Processor do
    it 'should coerce, validate and transform params and not raise' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :bin, type: :string, coerce: true, format: { with: /\A\d+\z/ }, transform: -> k, v { [k, v.to_i.to_s(2)] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { bin: 42 })
      processor = TypedParameters::Processor.new(schema:)

      processor.call(params)

      expect(params[:bin].value).to eq '101010'
    end

    it 'should coerce, validate and transform params and raise' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :bin, type: :string, coerce: true, format: { with: /\A\d+\z/ }, transform: -> k, v { [k, v.to_i.to_s(2)] } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { bin: 'foo' })
      processor = TypedParameters::Processor.new(schema:)

      expect { processor.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on param :if condition' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, if: -> { true } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      processor = TypedParameters::Processor.new(schema:)

      expect { processor.call(params) }.to_not raise_error
    end

    it 'should raise on param :if condition' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, if: -> { false } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      processor = TypedParameters::Processor.new(schema:)

      expect { processor.call(params) }.to raise_error TypedParameters::UnpermittedParameterError
    end

    it 'should not raise on param :unless condition' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, unless: -> { false } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      processor = TypedParameters::Processor.new(schema:)

      expect { processor.call(params) }.to_not raise_error
    end

    it 'should raise on param :unless condition' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, unless: -> { true } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'bar' })
      processor = TypedParameters::Processor.new(schema:)

      expect { processor.call(params) }.to raise_error TypedParameters::UnpermittedParameterError
    end
  end

  describe TypedParameters::Pipeline do
    it 'should reduce the pipeline steps in order' do
      pipeline = TypedParameters::Pipeline.new
      input    = 1

      pipeline << -> v { v += 1 }
      pipeline << -> v { v -= 2 }
      pipeline << -> v { v *= 3 }

      output = pipeline.call(input)

      expect(output).to eq 0
    end
  end

  describe TypedParameters::Bouncer do
    context 'with lenient schema' do
      it 'should bounce params with :if guard' do
        schema = TypedParameters::Schema.new type: :hash, strict: false do
          param :foo, type: :integer, if: :admin?
          param :bar, type: :integer, unless: :admin?
        end

        controller = Class.new(ActionController::Base) { def admin? = false }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        bouncer.call(params)

        expect(params).to_not have_keys :foo
        expect(params).to have_keys :bar
      end

      it 'should bounce params with :unless guard' do
        schema = TypedParameters::Schema.new type: :hash, strict: false do
          param :foo, type: :integer, if: -> { admin? }
          param :bar, type: :integer, unless: -> { admin? }
        end

        controller = Class.new(ActionController::Base) { def admin? = true }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        bouncer.call(params)

        expect(params).to have_keys :foo
        expect(params).to_not have_keys :bar
      end

      it 'should raise for invalid guard' do
        schema     = TypedParameters::Schema.new(type: :hash, strict: false) { param :foo, type: :integer, if: 'foo?' }
        controller = Class.new(ActionController::Base).new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to raise_error TypedParameters::InvalidMethodError
      end

      it 'should not bounce branches' do
        schema = TypedParameters::Schema.new type: :hash, strict: false do
          param :user, type: :hash, if: -> { true } do
            param :email, type: :string
            param :roles, type: :array, if: :admin? do
              items type: :string
            end
          end
        end

        controller = Class.new(ActionController::Base) { def admin? = true }.new
        user       = { user: { email: 'foo@keygen.example', roles: %w[admin] } }
        params     = TypedParameters::Parameterizer.new(schema:).call(value: user)
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        bouncer.call(params)

        expect(params.unwrap).to eq user
      end

      it 'should bounce branches' do
        schema = TypedParameters::Schema.new type: :hash, strict: false do
          param :user, type: :hash, if: -> { true } do
            param :email, type: :string
            param :roles, type: :array, if: :admin? do
              items type: :string
            end
          end
        end

        controller = Class.new(ActionController::Base) { def admin? = false }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { user: { email: 'foo@keygen.example', roles: %w[admin] } })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        bouncer.call(params)

        expect(params.unwrap).to eq user: { email: 'foo@keygen.example' }
      end
    end

    context 'with strict schema' do
      it 'should bounce params with :if guard' do
        schema = TypedParameters::Schema.new type: :hash, strict: true do
          param :foo, type: :integer, if: :admin?
          param :bar, type: :integer, unless: :admin?
        end

        controller = Class.new(ActionController::Base) { def admin? = false }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to raise_error { |err|
          expect(err).to be_a TypedParameters::UnpermittedParameterError
          expect(err.path.to_json_pointer).to eq '/foo'
        }
      end

      it 'should bounce params with :unless guard' do
        schema = TypedParameters::Schema.new type: :hash, strict: true do
          param :foo, type: :integer, if: -> { admin? }
          param :bar, type: :integer, unless: -> { admin? }
        end

        controller = Class.new(ActionController::Base) { def admin? = true }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1, bar: 2 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to raise_error { |err|
          expect(err).to be_a TypedParameters::UnpermittedParameterError
          expect(err.path.to_json_pointer).to eq '/bar'
        }
      end

      it 'should raise for invalid guard' do
        schema     = TypedParameters::Schema.new(type: :hash, strict: true) { param :foo, type: :integer, if: false }
        controller = Class.new(ActionController::Base).new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to raise_error TypedParameters::InvalidMethodError
      end

      it 'should not bounce branches' do
        schema = TypedParameters::Schema.new type: :hash, strict: true do
          param :user, type: :hash, if: -> { true } do
            param :email, type: :string
            param :roles, type: :array, if: :admin? do
              items type: :string
            end
          end
        end

        controller = Class.new(ActionController::Base) { def admin? = true }.new
        user       = { user: { email: 'foo@keygen.example', roles: %w[admin] } }
        params     = TypedParameters::Parameterizer.new(schema:).call(value: user)
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to_not raise_error
      end

      it 'should bounce branches' do
        schema = TypedParameters::Schema.new type: :hash, strict: true do
          param :user, type: :hash, if: -> { true } do
            param :email, type: :string
            param :roles, type: :array, if: :admin? do
              items type: :string
            end
          end
        end

        controller = Class.new(ActionController::Base) { def admin? = false }.new
        params     = TypedParameters::Parameterizer.new(schema:).call(value: { user: { email: 'foo@keygen.example', roles: %w[admin] } })
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        expect { bouncer.call(params) }.to raise_error { |err|
          expect(err).to be_a TypedParameters::UnpermittedParameterError
          expect(err.path.to_json_pointer).to eq '/user/roles'
        }
      end
    end
  end

  describe TypedParameters::Controller do
    subject {
      Class.new ActionController::Base do
        @controller_name = 'users'
        include TypedParameters::Controller
      end
    }

    it 'should define a local schema' do
      subject.typed_schema(:foo) { param :bar, type: :string }

      expect(subject.typed_schemas).to have_key :"#{subject}:foo"
    end

    it 'should define a global schema' do
      subject.typed_schema(:foo, namespace: nil) { param :bar, type: :string }

      expect(subject.typed_schemas).to have_key :foo
    end

    it 'should define a namespaced schema' do
      subject.typed_schema(:foo, namespace: :bar) { param :baz, type: :string }

      expect(subject.typed_schemas).to have_key :"bar:foo"
    end

    it 'should define a singular params handler' do
      subject.typed_params(on: :foo) { param :bar, type: :string }

      expect(subject.typed_handlers).to include params: {
        foo: anything,
      }
    end

    it 'should define multiple params handlers' do
      subject.typed_params(on: %i[foo bar baz]) { param :qux, type: :string }

      expect(subject.typed_handlers).to include params: {
        foo: anything,
        bar: anything,
        baz: anything,
      }
    end

    it 'should define a singular query param handler' do
      subject.typed_query(on: :foo) { param :bar, type: :string }

      expect(subject.typed_handlers).to include query: {
        foo: anything,
      }
    end

    it 'should define multiple query param handlers' do
      subject.typed_query(on: %i[foo bar baz]) { param :qux, type: :string }

      expect(subject.typed_handlers).to include query: {
        foo: anything,
        bar: anything,
        baz: anything,
      }
    end

    context 'without inheritance' do
      describe '.typed_schema' do
        it('should respond') { expect(subject).to respond_to :typed_schema }
      end

      describe '.typed_params' do
        it('should respond') { expect(subject).to respond_to :typed_params }
      end

      describe '.typed_query' do
        it('should respond') { expect(subject).to respond_to :typed_query }
      end

      describe '#typed_params' do
        it('should respond') { expect(subject.new).to respond_to :typed_params }
      end

      describe '#x_params' do
        it('should respond') { expect(subject.new).to respond_to :user_params }
      end

      describe '#typed_query' do
        it('should respond') { expect(subject.new).to respond_to :typed_query }
      end
    end

    context 'with inhertiance' do
      subject {
        parent = Class.new ActionController::Base do
          @controller_name = 'base'
          include TypedParameters::Controller
        end

        Class.new parent do
          @controller_name = 'users'
        end
      }

      describe '.typed_schema' do
        it('should respond') { expect(subject).to respond_to :typed_schema }
      end

      describe '.typed_params' do
        it('should respond') { expect(subject).to respond_to :typed_params }
      end

      describe '.typed_query' do
        it('should respond') { expect(subject).to respond_to :typed_query }
      end

      describe '#typed_params' do
        it('should respond') { expect(subject.new).to respond_to :typed_params }
      end

      describe '#x_params' do
        it('should not respond') { expect(subject.new).to_not respond_to :base_params }
        it('should respond') { expect(subject.new).to respond_to :user_params }
      end

      describe '#typed_query' do
        it('should respond') { expect(subject.new).to respond_to :typed_query }
      end
    end
  end

  describe 'controller', type: :controller do
    context 'with explicit action' do
      class self::UsersController < ActionController::Base; end

      controller self::UsersController do
        include TypedParameters::Controller

        typed_schema :explicit do
          param :email, type: :string, format: { with: /@/ }
          param :password, type: :string, length: { minimum: 8 }
        end

        def create = render json: user_params
        typed_params schema: :explicit,
                     on: :create
      end

      it 'should not raise' do
        expect { post :create, params: { email: 'foo@example.com', password: SecureRandom.hex } }
          .to_not raise_error
      end

      it 'should raise' do
        expect { post :create, params: { email: 'foo', password: SecureRandom.hex } }
          .to raise_error TypedParameters::InvalidParameterError
      end
    end

    context 'with deferred action' do
      class self::UsersController < ActionController::Base; end

      controller self::UsersController do
        include TypedParameters::Controller

        typed_schema :deferred do
          param :email, type: :string, format: { with: /@/ }
          param :password, type: :string, length: { minimum: 8 }
        end

        typed_params schema: :deferred
        def create = render json: user_params
      end

      it 'should not raise' do
        expect { post :create, params: { email: 'bar@example.com', password: SecureRandom.hex } }
          .to_not raise_error
      end

      it 'should raise' do
        expect { post :create, params: { password: 'secret' } }
          .to raise_error TypedParameters::InvalidParameterError
      end
    end

    context 'with no schema' do
      class self::UsersController < ActionController::Base; end

      controller self::UsersController do
        include TypedParameters::Controller

        def create = render json: user_params
      end

      it 'should raise' do
        expect { post :create }
          .to raise_error TypedParameters::UndefinedActionError
      end
    end

    context 'with multiple schemas' do
      class self::MentionsController < ActionController::Base; end

      controller self::MentionsController do
        include TypedParameters::Controller

        typed_query { param :dry_run, type: :boolean, optional: true }
        typed_params do
          param :username, type: :string, format: { with: /^@/ }
        end
        def create = render json: { params: mention_params, query: mention_query }
      end

      it 'should have correct params' do
        params = { username: "@#{SecureRandom.hex}" }
        query  = { dry_run: true }

        # FIXME(ezekg) There doesn't seem to be any other way to specify
        #              a POST body and query parameters separately in a
        #              test request. Thus, we have this hack.
        allow_any_instance_of(request.class).to receive(:request_parameters).and_return(params)
        allow_any_instance_of(request.class).to receive(:query_parameters).and_return(query)

        post :create

        body = JSON.parse(response.body, symbolize_names: true)

        expect(body[:params]).to eq params
        expect(body[:query]).to eq query
      end
    end

    context 'with JSONAPI schema' do
      class self::PostsController < ActionController::Base; end

      controller self::PostsController do
        include TypedParameters::Controller

        typed_params {
          format :jsonapi

          param :meta, type: :array, optional: true do
            items type: :hash do
              param :footnote, type: :string
            end
          end

          param :data, type: :hash do
            param :type, type: :string, inclusion: { in: %w[posts] }
            param :id, type: :string
          end
        }
        def create
          render json: {
            data: post_params(format: nil)[:data],
            meta: post_params(format: nil)[:meta],
            params: post_params,
          }
        end
      end

      it 'should have correct params' do
        meta = [{ footnote: '[1] foo' }, { footnote: '[2] bar' }]
        data = { type: 'posts', id: SecureRandom.base58 }

        post :create, params: { meta:, data: }

        body = JSON.parse(response.body, symbolize_names: true)

        expect(body[:params]).to eq data.slice(:id)
        expect(body[:meta]).to eq meta
        expect(body[:data]).to eq data
      end
    end
  end
end
