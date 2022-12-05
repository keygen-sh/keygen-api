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

      expect(grandchild.keys).to eq %w[bar]
    end
  end

  describe TypedParameters::Path do
    let(:path) { TypedParameters::Path.new(:foo, :bar, :baz, 42, :qux) }

    it 'should support JSON pointer paths' do
      expect(path.to_json_pointer).to eq '/foo/bar/baz/42/qux'
    end

    it 'should support dot notation paths' do
      expect(path.to_dot_notation).to eq 'foo.bar.baz.42.qux'
    end
  end

  describe TypedParameters::Parameter do
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

        expect(params.keys).to eq %w[a b c]
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

  describe TypedParameters::Rule do
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

      rule = Class.new(TypedParameters::Rule) do
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

    it 'should transform the params' do
      schema      = TypedParameters::Schema.new(type: :hash) { param :foo, type: :integer, transform: -> k, v { [:bar, v + 1] } }
      params      = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 1 })
      transformer = TypedParameters::Transformer.new(schema:)

      transformer.call(params)

      expect(params[:foo].key).to eq :bar
      expect(params[:foo].value).to eq 2
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
        user       = { 'user' => { 'email' => 'foo@keygen.example', 'roles' => %w[admin] } }
        params     = TypedParameters::Parameterizer.new(schema:).call(value: user)
        bouncer    = TypedParameters::Bouncer.new(controller:, schema:)

        bouncer.call(params)

        expect(params.unsafe).to eq user
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

        expect(params.unsafe).to eq 'user' => { 'email' => 'foo@keygen.example' }
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
        user       = { 'user' => { 'email' => 'foo@keygen.example', 'roles' => %w[admin] } }
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

    it 'should define a named schema' do
      subject.typed_schema(:foo) { param :bar, type: :string }

      expect(subject.typed_schemas).to include foo: anything
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
    class self::UsersController < ActionController::Base; end

    controller self::UsersController do
      include TypedParameters::Controller

      typed_schema :user do
        param :first_name, type: :string, optional: true
        param :last_name, type: :string, optional: true
        param :email, type: :string, format: { with: /@/ }
        param :password, type: :string, length: { minimum: 8 }
        param :metadata, type: :hash, optional: true
        param :role, type: :string, optional: true, if: :admin?
      end

      def create = render json: { params: user_params, query: nil }
      typed_params schema: :user,
                   on: :create

      typed_params schema: :user
      typed_query { param :force, type: :boolean, optional: true }
      def update = render json: { params: user_params, query: user_query }

      def destroy = render json: { params: user_params, query: nil }

      private

      def admin? = false
    end

    it 'should not raise for predefined schema' do
      expect { post :create, params: { email: 'foo@example.com', password: SecureRandom.hex } }
        .to_not raise_error
    end

    it 'should raise for predefined schema' do
      expect { post :create, params: { email: 'foo', password: SecureRandom.hex } }
        .to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise for deferred schema' do
      expect { put :update, params: { id: 1, email: 'bar@example.com', password: SecureRandom.hex } }
        .to_not raise_error
    end

    it 'should raise for deferred schema' do
      expect { put :update, params: { id: 1, password: 'secret' } }
        .to raise_error TypedParameters::InvalidParameterError
    end

    it 'should raise for undefined schema' do
      expect { delete :destroy, params: { id: 1 } }
        .to raise_error TypedParameters::UndefinedActionError
    end

    it 'should return params and query' do
      params = { email: 'bar@example.com', password: SecureRandom.hex }
      query  = { force: true }

      # FIXME(ezekg) There doesn't seem to be any other way to specify
      #              a POST body and query parameters separately in a
      #              test request. Thus, we have this hack.
      allow_any_instance_of(request.class).to receive(:request_parameters).and_return(params)
      allow_any_instance_of(request.class).to receive(:query_parameters).and_return(query)

      patch :update, params: { id: 1 }

      body = JSON.parse(response.body, symbolize_names: true)

      expect(body[:params]).to eq params
      expect(body[:query]).to eq query
    end
  end

  # # Quick and dirty mock controller context for a request
  # def request(params = {}, action = :create)
  #   OpenStruct.new(
  #     action_name: action,
  #     "#{action}": nil,
  #     params: params,
  #     request: OpenStruct.new(
  #       raw_post: JSON.generate(params),
  #       format: Mime[:json]
  #     )
  #   )
  # end

  # context "type checks" do
  #   it "should allow requests that contain valid types" do
  #     params = lambda {
  #       ctx = request key: "value"

  #       TypedParameters.build ctx do
  #         on(:create) { param :key, type: :string }
  #       end
  #     }
  #     expect(params.call).to eq "key" => "value"
  #   end

  #   it "should disallow requests that contain a type mismatch" do
  #     params = lambda {
  #       ctx = request key: 1

  #       TypedParameters.build ctx do
  #         on(:create) { param :key, type: :string }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/key"
  #     }
  #   end

  #   it "should allow requests that contain a type mismatch that can be coerced" do
  #     params = lambda {
  #       ctx = request key: "1"

  #       TypedParameters.build ctx do
  #         on(:create) { param :key, type: :integer, coerce: true }
  #       end
  #     }
  #     expect(params.call).to eq "key" => 1
  #   end

  #   it "should disallow requests that contain a type mismatch that cannot be coerced" do
  #     params = lambda {
  #       ctx = request key: Object.new

  #       TypedParameters.build ctx do
  #         on(:create) { param :key, type: :integer, coerce: true }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/key"
  #     }
  #   end

  #   it "should disallow requests that contain null values as missing" do
  #     params = lambda {
  #       ctx = request key: nil

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :key, type: :string
  #         end
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/key"
  #     }
  #   end

  #   it "should allow requests that contain optional null values" do
  #     params = lambda {
  #       ctx = request key: nil

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :key, type: :string, optional: true
  #         end
  #       end
  #     }
  #     expect(&params).to_not raise_error
  #     expect(params.call).to_not include "key" => nil
  #   end

  #   context  "should allow requests that contain optional null values with varied input key casing" do
  #     it "pascal casing" do
  #       params = lambda {
  #         ctx = request PascalKey: nil

  #         TypedParameters.build ctx do
  #           on :create do
  #             param :pascal_key, type: :string, optional: true
  #           end
  #         end
  #       }
  #       expect(&params).to_not raise_error
  #       expect(params.call).to be_empty
  #     end

  #     it "snake casing" do
  #       params = lambda {
  #         ctx = request snake_key: nil

  #         TypedParameters.build ctx do
  #           on :create do
  #             param :snake_key, type: :string, optional: true
  #           end
  #         end
  #       }
  #       expect(&params).to_not raise_error
  #       expect(params.call).to be_empty
  #     end

  #     it "camel casing" do
  #       params = lambda {
  #         ctx = request camelKey: nil

  #         TypedParameters.build ctx do
  #           on :create do
  #             param :camel_key, type: :string, optional: true
  #           end
  #         end
  #       }
  #       expect(&params).to_not raise_error
  #       expect(params.call).to be_empty
  #     end

  #     it "meme casing" do
  #       params = lambda {
  #         ctx = request mEmEkEy: nil

  #         TypedParameters.build ctx do
  #           on :create do
  #             param :meme_key, type: :string, optional: true
  #           end
  #         end
  #       }
  #       expect(&params).to_not raise_error
  #       expect(params.call).to be_empty
  #     end
  #   end

  #   it "should allow requests that omit optional values" do
  #     params = lambda {
  #       ctx = request

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :key, type: :string, optional: true
  #         end
  #       end
  #     }
  #     expect(&params).to_not raise_error
  #     expect(params.call).to_not include "key" => nil
  #   end

  #   it "should allow requests that contain allowed nil values" do
  #     params = lambda {
  #       ctx = request "foo" => nil

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :foo, type: :hash, allow_nil: true do
  #             param :bar, type: :string
  #           end
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "foo" => nil
  #   end

  #   it "should allow requests that contain optional allowed nil values" do
  #     params = lambda {
  #       ctx = request "key" => nil

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :key, type: :string, optional: true, allow_nil: true
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "key" => nil
  #   end

  #   it "should not contain allowed nil param if value is missing" do
  #     params = lambda {
  #       ctx = request({})

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :key, type: :string, optional: true, allow_nil: true
  #         end
  #       end
  #     }
  #     expect(params.call).to_not eq "key" => nil
  #   end

  #   it "should allow requests that contain a hash with scalar values" do
  #     params = lambda {
  #       ctx = request hash: { key1: "value", key2: 1, key3: true, key4: false }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash }
  #       end
  #     }
  #     expect(params.call).to eq "hash" => {
  #       "key1" => "value",
  #       "key2" => 1,
  #       "key3" => true,
  #       "key4" => false
  #     }
  #   end

  #   it "should disallow requests that contain a hash with non-scalar values" do
  #     params = lambda {
  #       ctx = request hash: { key1: "value", key2: 1, key3: true, key4: false, nested: { key: "value" } }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash"
  #     }
  #   end

  #   it "should allow requests that contain a hash with non-scalar values when non-scalars are allowed (hash)" do
  #     params = lambda {
  #       ctx = request hash: { nested: { key: "value" } }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(params.call).to eq "hash" => { "nested" => { "key" => "value" } }
  #   end

  #   it "should allow requests that contain a hash with non-scalar values when non-scalars are allowed (array)" do
  #     params = lambda {
  #       ctx = request hash: { nested: [1, 2, 3] }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(params.call).to eq "hash" => { "nested" => [1, 2, 3] }
  #   end

  #   it "should disallow requests that contain a nested hash with non-scalar values when non-scalars are allowed (hash)" do
  #     params = lambda {
  #       ctx = request hash: { key: { nested_key: { key: "value" } } }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash/key/nestedKey"
  #     }
  #   end

  #   it "should disallow requests that contain a nested hash with non-scalar values when non-scalars are allowed (array)" do
  #     params = lambda {
  #       ctx = request hash: { key: { nested_key: ["value"] } }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash/key/nestedKey"
  #     }
  #   end

  #   it "should disallow requests that contain a nested array with non-scalar values when non-scalars are allowed (hash)" do
  #     params = lambda {
  #       ctx = request hash: { nested: [1, 2, { key: "value" }] }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash/nested/2"
  #     }
  #   end

  #   it "should disallow requests that contain a nested array with non-scalar values when non-scalars are allowed (array)" do
  #     params = lambda {
  #       ctx = request hash: { nested: [1, 2, [3]] }

  #       TypedParameters.build ctx do
  #         on(:create) { param :hash, type: :hash, allow_non_scalars: true }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash/nested/2"
  #     }
  #   end

  #   it "should allow requests that contain a nested hash" do
  #     params = lambda {
  #       ctx = request hash: { nested: { key: "value" } }

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :hash, type: :hash do
  #             param :nested, type: :hash
  #           end
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "hash" => { "nested" => { "key" => "value" } }
  #   end

  #   it "should disallow requests that contain a nested hash with missing keys" do
  #     params = lambda {
  #       ctx = request hash: { }

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :hash, type: :hash do
  #             param :nested, type: :hash
  #           end
  #         end
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/hash/nested"
  #     }
  #   end

  #   it "should allow requests that contain an array of scalar values" do
  #     params = lambda {
  #       ctx = request array: [1, 2, 3]

  #       TypedParameters.build ctx do
  #         on(:create) { param :array, type: :array }
  #       end
  #     }
  #     expect(params.call).to eq "array" => [1, 2, 3]
  #   end

  #   it "should disallow requests that contain an array of non-scalar values" do
  #     params = lambda {
  #       ctx = request array: [[1, 2], [3]]

  #       TypedParameters.build ctx do
  #         on(:create) { param :array, type: :array }
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/array/0"
  #     }
  #   end

  #   # it "should allow requests that contain an array of non-scalar values when non-scalars are allowed" do
  #   #   params = lambda {
  #   #     ctx = request array: [1, [2], { key: "value" }]

  #   #     TypedParameters.build ctx do
  #   #       on(:create) { param :array, type: :array }
  #   #     end
  #   #   }
  #   #   expect(params.call).to eq "array" => [1, 2, { "key" => "value" }]
  #   # end

  #   # it "should disallow requests that contain an array of nested non-scalar values when non-scalaras are allowed" do
  #   #   params = lambda {
  #   #     ctx = request array: [[1, 2], [{ key: "value" }]]

  #   #     TypedParameters.build ctx do
  #   #       on(:create) { param :array, type: :array }
  #   #     end
  #   #   }
  #   #   expect(&params).to raise_error { |err|
  #   #     expect(err).to be_a TypedParameters::InvalidParameterError
  #   #     expect(err.source).to include pointer: "/array/1/0"
  #   #   }
  #   # end

  #   it "should allow requests that contain an array of hashes" do
  #     params = lambda {
  #       ctx = request array: [{ key: "value" }, { key: "value" }]

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :array, type: :array do
  #             items type: :hash do
  #               param :key, type: :string
  #             end
  #           end
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "array" => [
  #       { "key" => "value" }, { "key" => "value" }
  #     ]
  #   end

  #   it "should disallow requests that contain an array of hashes with a type error" do
  #     params = lambda {
  #       ctx = request array: [{ some_key: "value" }, { some_key: 3 }]

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :array, type: :array do
  #             items type: :hash do
  #               param :some_key, type: :string
  #             end
  #           end
  #         end
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/array/1/someKey"
  #     }
  #   end
  # end

  # context "permits" do
  #   it "should allow requests that contain permitted keys" do
  #     params = lambda {
  #       ctx = request a: "value", b: 1

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :a, type: :string
  #           param :b, type: :integer
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "a" => "value", "b" => 1
  #   end

  #   it "should filter requests that contain unpermitted keys" do
  #     params = lambda {
  #       ctx = request a: "value", b: 1, c: false

  #       TypedParameters.build ctx do
  #         on :create do
  #           param :a, type: :string
  #           param :b, type: :integer
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "a" => "value", "b" => 1
  #   end

  #   it "should disallow requests that contain unpermitted keys when in strict mode" do
  #     params = lambda {
  #       ctx = request a: "value", b: 1, c: false

  #       TypedParameters.build ctx do
  #         options strict: true

  #         on :create do
  #           param :a, type: :string
  #           param :b, type: :integer
  #         end
  #       end
  #     }
  #     expect(&params).to raise_error TypedParameters::UnpermittedParametersError
  #   end

  #   it "should disallow requests that contain a top-level optional hash that is nil" do
  #     params = lambda {
  #       ctx = request data: nil

  #       TypedParameters.build ctx do
  #         options strict: true

  #         on :create do
  #           param :data, type: :hash, optional: true do
  #             param :type, type: :string
  #           end
  #         end
  #       end
  #     }
  #     expect(&params).to raise_error { |err|
  #       expect(err).to be_a TypedParameters::InvalidParameterError
  #       expect(err.source).to include pointer: "/data"
  #     }
  #   end
  # end

  # context "validations" do
  #   # TODO: Write spec for param validations
  # end

  # context "transforms" do
  #   it "should transform a hash to a string value" do
  #     params = lambda {
  #       ctx = request key: { foo: "value" }

  #       TypedParameters.build ctx do
  #         options strict: true

  #         on :create do
  #           param :key, type: :hash, transform: -> (k, v) { [k, v[:foo]] }
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "key" => "value"
  #   end

  #   it "should transform a string to a hash value" do
  #     params = lambda {
  #       ctx = request key: "value"

  #       TypedParameters.build ctx do
  #         options strict: true

  #         on :create do
  #           param :key, type: :string, transform: -> (k, v) { [k, { foo: v }] }
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "key" => { "foo" => "value" }
  #   end

  #   it "should transform the param's key" do
  #     params = lambda {
  #       ctx = request key: "value"

  #       TypedParameters.build ctx do
  #         options strict: true

  #         on :create do
  #           param :key, type: :string, transform: -> (k, v) { ["#{k}_attributes", v] }
  #         end
  #       end
  #     }
  #     expect(params.call).to eq "key_attributes" => "value"
  #   end

  #   # TODO: Write additional specs for param transformations
  # end

  # # context "format" do
  # #   it "should deserialize a JSONAPI payload" do
  # #     params = lambda {
  # #       ctx = request type: 'user', id: '1', attributes: { email: 'zeke@keygen.example' }

  # #       TypedParameters.build ctx, format: :jsonapi do
  # #         options strict: true

  # #         on :create do
  # #           param :type, type: :string
  # #           param :id, type: :string
  # #           param :attributes, type: :hash do
  # #             param :email, type: :string
  # #           end
  # #         end
  # #       end
  # #     }
  # #     expect(params.call).to eq foo: 1
  # #   end
  # # end
end
