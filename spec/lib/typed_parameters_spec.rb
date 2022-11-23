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

    it 'should raise on blank param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, allow_blank: false }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: '' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on inclusion param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: %w[a b c] }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'b' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on inclusion param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, inclusion: %w[a b c] }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on exclusion param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: %w[a b c] }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'd' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on exclusion param' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, exclusion: %w[a b c] }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'c' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to raise_error TypedParameters::InvalidParameterError
    end

    it 'should not raise on custom param validation' do
      schema    = TypedParameters::Schema.new(type: :hash) { param :foo, type: :string, validate: -> v { v == 'ok' } }
      params    = TypedParameters::Parameterizer.new(schema:).call(value: { foo: 'ok' })
      validator = TypedParameters::Validator.new(schema:)

      expect { validator.call(params) }.to_not raise_error
    end

    it 'should raise on custom param validation' do
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
