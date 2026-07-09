# frozen_string_literal: true

require 'temporary_tables'
require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'denormalizable'

describe Denormalizable do
  around do |example|
    adapter_was, ActiveJob::Base.queue_adapter = ActiveJob::Base.queue_adapter, :test

    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter_was
  end

  describe '.denormalizes' do
    temporary_table :publishers do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :books do |t|
      t.references :publisher
      t.string :publisher_name
      t.string :name
      t.timestamps
    end

    temporary_table :reviews do |t|
      t.references :book
      t.string :book_name
      t.timestamps
    end

    temporary_model :publisher do
      has_many :books
      has_one :contract
    end

    temporary_model :book do
      include Denormalizable::Model

      belongs_to :publisher
      has_one :contract
      has_many :reviews
    end

    temporary_model :review do
      belongs_to :book
    end

    context 'when denormalizing :from' do
      it 'should not raise for valid :from association' do
        expect { Book.denormalizes :name, from: :publisher }.to_not raise_error
      end

      it 'should raise for invalid :from association' do
        expect { Book.denormalizes :name, from: :foo }.to raise_error ArgumentError
      end

      it 'should raise for collection :from association' do
        expect { Book.denormalizes :name, from: :reviews }.to raise_error ArgumentError
      end

      it 'should raise for has_one :from association' do
        expect { Book.denormalizes :name, from: :contract }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { Book.denormalizes :name, from: :publisher, prefix: true }.to_not raise_error
      end

      it 'should not raise with false :prefix' do
        expect { Book.denormalizes :name, from: :publisher, prefix: false }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { Book.denormalizes :name, from: :publisher, prefix: :foo }.to_not raise_error
      end
    end

    context 'when denormalizing :to' do
      it 'should not raise for valid :to association' do
        expect { Book.denormalizes :name, to: :reviews }.to_not raise_error
      end

      it 'should raise for invalid :to association' do
        expect { Book.denormalizes :name, to: :foo }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { Book.denormalizes :name, to: :reviews, prefix: true }.to_not raise_error
      end

      it 'should not raise with false :prefix' do
        expect { Book.denormalizes :name, to: :reviews, prefix: false }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { Book.denormalizes :name, to: :reviews, prefix: :foo }.to_not raise_error
      end
    end

    context 'when denormalizing :from :through' do
      it 'should not raise for valid :through association' do
        expect { Book.denormalizes :name, from: :imprint, through: :publisher }.to_not raise_error
      end

      it 'should raise for invalid :through association' do
        expect { Book.denormalizes :name, from: :imprint, through: :foo }.to raise_error ArgumentError
      end

      it 'should raise for collection :through association' do
        expect { Book.denormalizes :name, from: :imprint, through: :reviews }.to raise_error ArgumentError
      end

      it 'should raise for has_one :through association' do
        expect { Book.denormalizes :name, from: :imprint, through: :contract }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { Book.denormalizes :name, from: :imprint, through: :publisher, prefix: true }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { Book.denormalizes :name, from: :imprint, through: :publisher, prefix: :foo }.to_not raise_error
      end

      it 'should not raise with :as' do
        expect { Book.denormalizes :name, from: :imprint, through: :publisher, as: :imprint_name }.to_not raise_error
      end
    end

    context 'when denormalizing :to :through' do
      it 'should not raise for valid :through association' do
        expect { Book.denormalizes :name, to: :books, through: :publisher }.to_not raise_error
      end

      it 'should raise for invalid :through association' do
        expect { Book.denormalizes :name, to: :books, through: :foo }.to raise_error ArgumentError
      end

      it 'should raise for collection :through association' do
        expect { Book.denormalizes :name, to: :books, through: :reviews }.to raise_error ArgumentError
      end

      it 'should not raise with true :prefix' do
        expect { Book.denormalizes :name, to: :books, through: :publisher, prefix: true }.to_not raise_error
      end

      it 'should not raise with symbol :prefix' do
        expect { Book.denormalizes :name, to: :books, through: :publisher, prefix: :foo }.to_not raise_error
      end

      it 'should not raise with :as' do
        expect { Book.denormalizes :name, to: :books, through: :publisher, as: :book_name }.to_not raise_error
      end

      it 'should not raise with :inverse_of' do
        expect { Book.denormalizes :name, to: :books, through: :publisher, inverse_of: :publisher }.to_not raise_error
      end

      it 'should not raise for singular :to association' do
        expect { Book.denormalizes :name, to: :contract, through: :publisher }.to_not raise_error
      end
    end

    context 'when denormalizing with :inverse_of' do
      it 'should raise without :through' do
        expect { Book.denormalizes :name, to: :reviews, inverse_of: :book }.to raise_error ArgumentError
      end

      it 'should raise without :to' do
        expect { Book.denormalizes :name, from: :imprint, through: :publisher, inverse_of: :book }.to raise_error ArgumentError
      end
    end

    context 'when denormalizing with :as' do
      it 'should not raise for single attribute' do
        expect { Book.denormalizes :name, from: :publisher, as: :foo }.to_not raise_error
      end

      it 'should raise for multiple attributes' do
        expect { Book.denormalizes :name, :id, from: :publisher, as: :foo }.to raise_error ArgumentError
      end

      it 'should raise for both :prefix and :as' do
        expect { Book.denormalizes :name, from: :publisher, prefix: :foo, as: :bar }.to raise_error ArgumentError
      end
    end

    it 'should raise for missing args' do
      expect { Book.denormalizes :name }.to raise_error ArgumentError
    end

    it 'should raise for both :from and :to' do
      expect { Book.denormalizes :name, from: :publisher, to: :reviews }.to raise_error ArgumentError
    end

    it 'should register denormalizations' do
      Book.denormalizes :name, from: :publisher, prefix: true
      Book.denormalizes :name, to: :reviews, as: :book_name
      Book.denormalizes :name, from: :imprint, through: :publisher, as: :imprint_name
      Book.denormalizes :id, to: :books, through: :publisher, as: :book_id

      expect(Book.denormalizations).to include(
        publisher_name: an_instance_of(Denormalizable::Denormalization::From),
        name: an_instance_of(Denormalizable::Denormalization::To),
        imprint_name: an_instance_of(Denormalizable::Denormalization::From),
        id: an_instance_of(Denormalizable::Denormalization::To),
      )

      expect(Book.denormalizations[:publisher_name].association).to be_an_instance_of Denormalizable::Association::Singular
      expect(Book.denormalizations[:name].association).to be_an_instance_of Denormalizable::Association::Collection
      expect(Book.denormalizations[:imprint_name].association).to be_an_instance_of Denormalizable::Association::Through
      expect(Book.denormalizations[:id].association).to be_an_instance_of Denormalizable::Association::Through

      expect(Book.denormalizations.values).to all be_frozen
      expect(Book.denormalized_attributes).to eq Set[:publisher_name, :name, :imprint_name, :id]
    end
  end

  describe Denormalizable::Denormalization do
    it 'should raise for abstract methods' do
      denormalization = Denormalizable::Denormalization.new(nil, attribute: :name, association: nil)

      expect { denormalization.key }.to raise_error NotImplementedError
      expect { denormalization.instrument! }.to raise_error NotImplementedError
    end
  end

  describe 'denormalizing :from a singular association' do
    temporary_table :publishers do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :imprints do |t|
      t.references :publisher
      t.string :name
      t.timestamps
    end

    temporary_table :books do |t|
      t.references :imprint
      t.references :publisher
      t.string :imprint_name
      t.string :name
      t.timestamps
    end

    temporary_model :publisher do
      has_many :imprints
    end

    temporary_model :imprint do
      belongs_to :publisher, optional: true
      has_many :books
    end

    temporary_model :book do
      include Denormalizable::Model

      belongs_to :imprint
      belongs_to :publisher, optional: true

      denormalizes :name, from: :imprint, prefix: true
      denormalizes :publisher_id, from: :imprint
    end

    context 'on initialization' do
      it 'should denormalize from the source' do
        imprint = Imprint.create!(name: 'Del Rey')

        expect(Book.new(imprint:).imprint_name).to eq 'Del Rey'
      end
    end

    context 'on create' do
      it 'should denormalize from a persisted source' do
        imprint = Imprint.create!(name: 'Del Rey')
        book    = Book.create!(imprint:)

        expect(book.imprint_name).to eq 'Del Rey'
      end

      it 'should denormalize from an unpersisted source' do
        imprint = Imprint.new(name: 'Del Rey')
        book    = Book.create!(imprint:)

        expect(book.imprint_name).to eq 'Del Rey'
      end

      it 'should denormalize a foreign key from an unpersisted source via its association' do
        publisher = Publisher.create!(name: 'Penguin')
        imprint   = Imprint.new(name: 'Del Rey', publisher:)
        book      = Book.create!(imprint:)

        expect(book.publisher_id).to eq publisher.id
      end
    end

    context 'on update' do
      it 'should denormalize on association change' do
        book    = Book.create!(imprint: Imprint.create!(name: 'Del Rey'))
        imprint = Imprint.create!(name: 'Tor')

        book.update!(imprint:)

        expect(book.imprint_name).to eq 'Tor'
      end

      it 'should denormalize on foreign key change' do
        book    = Book.create!(imprint: Imprint.create!(name: 'Del Rey'))
        imprint = Imprint.create!(name: 'Tor')

        book.update!(imprint_id: imprint.id)

        expect(book.reload.imprint_name).to eq 'Tor'
      end

      it 'should not denormalize on unrelated change' do
        book = Book.create!(imprint: Imprint.create!(name: 'Del Rey'))

        expect { book.update!(name: 'The Book') }.to_not change { book.imprint_name }
      end

      it 'should raise when the denormalized attribute is modified directly' do
        book = Book.create!(imprint: Imprint.create!(name: 'Del Rey'))

        expect { book.update!(imprint_name: 'Tor') }.to raise_error ActiveRecord::RecordInvalid

        expect(book.errors.details).to include imprint_name: [include(error: :not_allowed)]
      end

      it 'should raise on the association when a denormalized foreign key is modified directly' do
        book      = Book.create!(imprint: Imprint.create!(name: 'Del Rey', publisher: Publisher.create!(name: 'Penguin')))
        publisher = Publisher.create!(name: 'Macmillan')

        expect { book.update!(publisher_id: publisher.id) }.to raise_error ActiveRecord::RecordInvalid

        expect(book.errors.details).to include publisher: [include(error: :not_allowed)]
      end
    end
  end

  describe 'denormalizing :from a :through association' do
    temporary_table :authors do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :agents do |t|
      t.references :client, polymorphic: true
      t.string :name
      t.timestamps
    end

    temporary_table :contracts do |t|
      t.references :party, polymorphic: true
      t.string :agent_name
      t.timestamps
    end

    temporary_model :author do
      has_one :agent, as: :client
      has_many :contracts, as: :party
    end

    temporary_model :agent do
      belongs_to :client, polymorphic: true
    end

    temporary_model :contract do
      include Denormalizable::Model

      belongs_to :party, polymorphic: true

      denormalizes :name, from: :agent, through: :party, as: :agent_name
    end

    context 'on create' do
      it 'should denormalize from a persisted source' do
        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        contract = Contract.create!(party: author)

        expect(contract.agent_name).to eq 'WME'
      end

      it 'should denormalize from an unpersisted source' do
        author = Author.new(name: 'Jane')
        author.build_agent(name: 'WME')

        contract = Contract.create!(party: author)

        expect(contract.agent_name).to eq 'WME'
      end
    end

    context 'on update' do
      it 'should denormalize on :through association change' do
        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        other = Author.create!(name: 'John')
        other.create_agent!(name: 'CAA')

        contract = Contract.create!(party: author)
        contract.update!(party: other)

        expect(contract.agent_name).to eq 'CAA'
      end

      it 'should raise when the denormalized attribute is modified directly' do
        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        contract = Contract.create!(party: author)

        expect { contract.update!(agent_name: 'CAA') }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'denormalizing :to a singular association' do
    temporary_table :authors do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :contracts do |t|
      t.references :author
      t.string :author_name
      t.timestamps
    end

    temporary_model :author do
      include Denormalizable::Model

      has_one :contract

      denormalizes :name, to: :contract, prefix: :author
    end

    temporary_model :contract do
      belongs_to :author
    end

    context 'on create' do
      it 'should denormalize to an unpersisted target' do
        author = Author.new(name: 'Jane')
        author.build_contract
        author.save!

        expect(author.contract.author_name).to eq 'Jane'
      end
    end

    context 'on update' do
      it 'should denormalize to a persisted target' do
        author   = Author.create!(name: 'Jane')
        contract = author.create_contract!(author_name: 'Jane')

        author.update!(name: 'Jane Doe')

        expect(contract.reload.author_name).to eq 'Jane Doe'
      end

      it 'should denormalize inline, not via the async job' do
        author   = Author.create!(name: 'Jane')
        contract = author.create_contract!(author_name: 'Jane')

        expect { author.update!(name: 'Jane Doe') }.to_not have_enqueued_job(Denormalizable::DenormalizeAssociationAsyncJob)
      end

      it 'should not raise without a target' do
        author = Author.create!(name: 'Jane')

        expect { author.update!(name: 'Jane Doe') }.to_not raise_error
      end
    end
  end

  describe 'denormalizing :to a collection association' do
    temporary_table :publishers do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :books do |t|
      t.references :publisher
      t.string :publisher_name
      t.timestamps
    end

    temporary_model :publisher do
      include Denormalizable::Model

      has_many :books

      denormalizes :name, to: :books, prefix: :publisher
    end

    temporary_model :book do
      belongs_to :publisher
    end

    context 'on create' do
      it 'should denormalize to unpersisted targets' do
        publisher = Publisher.new(name: 'Penguin')
        publisher.books.build
        publisher.save!

        expect(publisher.books.first.publisher_name).to eq 'Penguin'
      end
    end

    context 'on update' do
      it 'should denormalize to persisted targets' do
        publisher = Publisher.create!(name: 'Penguin')
        books     = 3.times.map { publisher.books.create!(publisher_name: 'Penguin') }

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          publisher.update!(name: 'Penguin Random House')
        end

        expect(books.map { it.reload.publisher_name }).to all eq 'Penguin Random House'
      end

      it 'should not denormalize to concurrently modified targets' do
        publisher = Publisher.create!(name: 'Penguin')
        book      = publisher.books.create!(publisher_name: 'Penguin')
        modified  = publisher.books.create!(publisher_name: 'Penguin')

        # simulate a concurrent write between enqueue and perform
        modified.update_columns(publisher_name: 'Macmillan')

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          publisher.update!(name: 'Penguin Random House')
        end

        expect(book.reload.publisher_name).to eq 'Penguin Random House'
        expect(modified.reload.publisher_name).to eq 'Macmillan'
      end

      it 'should denormalize in batches' do
        stub_const('Denormalizable::DENORMALIZE_ASSOCIATION_ASYNC_BATCH_SIZE', 2)

        publisher = Publisher.create!(name: 'Penguin')

        3.times { publisher.books.create!(publisher_name: 'Penguin') }

        expect { publisher.update!(name: 'Penguin Random House') }.to have_enqueued_job(Denormalizable::DenormalizeAssociationAsyncJob).exactly(2).times
      end
    end
  end

  describe 'denormalizing :to a singular :through association' do
    temporary_table :publishers do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :books do |t|
      t.references :publisher
      t.string :name
      t.timestamps
    end

    temporary_table :contracts do |t|
      t.references :publisher
      t.string :book_name
      t.timestamps
    end

    temporary_model :publisher do
      has_many :books
      has_one :contract
    end

    temporary_model :contract do
      belongs_to :publisher
    end

    temporary_model :book do
      include Denormalizable::Model

      belongs_to :publisher

      denormalizes :name, to: :contract, through: :publisher, as: :book_name
    end

    context 'on create' do
      it 'should denormalize to a persisted target' do
        publisher = Publisher.create!(name: 'Penguin')
        contract  = publisher.create_contract!

        Book.create!(publisher:, name: 'It')

        expect(contract.reload.book_name).to eq 'It'
      end
    end

    context 'on update' do
      it 'should denormalize to a persisted target' do
        publisher = Publisher.create!(name: 'Penguin')
        contract  = publisher.create_contract!
        book      = Book.create!(publisher:, name: 'It')

        book.update!(name: 'The Stand')

        expect(contract.reload.book_name).to eq 'The Stand'
      end

      it 'should not raise without a target' do
        publisher = Publisher.create!(name: 'Penguin')
        book      = Book.create!(publisher:, name: 'It')

        expect { book.update!(name: 'The Stand') }.to_not raise_error
      end
    end
  end

  describe 'denormalizing :to a :through association' do
    temporary_table :authors do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :publishers do |t|
      t.string :name
      t.timestamps
    end

    temporary_table :agents do |t|
      t.references :client, polymorphic: true
      t.string :name
      t.timestamps
    end

    temporary_table :contracts do |t|
      t.references :party, polymorphic: true
      t.references :publisher
      t.string :agent_name
      t.timestamps
    end

    temporary_model :author do
      has_one :agent, as: :client
      has_many :contracts, as: :party
    end

    # NB(ezekg) Publisher#contracts is scoped to the publisher, not to the
    #           publisher as a party, i.e. it also contains contracts of
    #           authors signed with the publisher -- the ambiguous case
    #           :inverse_of resolves.
    temporary_model :publisher do
      has_one :agent, as: :client
      has_many :contracts
    end

    temporary_model :agent do
      include Denormalizable::Model

      belongs_to :client, polymorphic: true

      denormalizes :name, to: :contracts, through: :client, inverse_of: :party, as: :agent_name
    end

    temporary_model :contract do
      belongs_to :party, polymorphic: true
      belongs_to :publisher, optional: true
    end

    context 'on initialization' do
      it 'should only denormalize to loaded records owned by the :through record' do
        publisher = Publisher.create!(name: 'Penguin')
        publisher.create_agent!(name: 'WME')

        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        publisher_contract = Contract.create!(party: publisher, publisher:, agent_name: 'WME')
        author_contract    = Contract.create!(party: author, publisher:, agent_name: 'WME')

        contracts = publisher.contracts.load # preload the ambiguous relation

        Agent.new(client: publisher, name: 'CAA')

        expect(contracts.find { it.id == publisher_contract.id }.agent_name).to eq 'CAA'
        expect(contracts.find { it.id == author_contract.id }.agent_name).to eq 'WME'
      end

      it 'should not load an unloaded relation' do
        publisher = Publisher.create!(name: 'Penguin')

        Agent.new(client: publisher, name: 'WME')

        expect(publisher.contracts.loaded?).to be false
      end
    end

    context 'on create' do
      it 'should denormalize to stale records owned by the :through record' do
        publisher = Publisher.create!(name: 'Penguin')
        publisher.create_agent!(name: 'WME').delete # leaves stale agent_name values behind

        publisher_contract = Contract.create!(party: publisher, publisher:, agent_name: 'WME')

        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        author_contract = Contract.create!(party: author, publisher:, agent_name: 'WME')

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          Agent.create!(client: publisher, name: 'CAA')
        end

        expect(publisher_contract.reload.agent_name).to eq 'CAA'
        expect(author_contract.reload.agent_name).to eq 'WME'
      end
    end

    context 'on update' do
      it 'should only denormalize to records owned by the :through record' do
        publisher = Publisher.create!(name: 'Penguin')
        agent     = publisher.create_agent!(name: 'WME')

        author = Author.create!(name: 'Jane')
        author.create_agent!(name: 'WME')

        publisher_contract = Contract.create!(party: publisher, publisher:, agent_name: 'WME')
        author_contract    = Contract.create!(party: author, publisher:, agent_name: 'WME')

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          agent.update!(name: 'CAA')
        end

        expect(publisher_contract.reload.agent_name).to eq 'CAA'
        expect(author_contract.reload.agent_name).to eq 'WME'
      end

      it 'should denormalize to records of a polymorphic :through record' do
        author = Author.create!(name: 'Jane')
        agent  = author.create_agent!(name: 'WME')

        contract = Contract.create!(party: author, agent_name: 'WME')

        perform_enqueued_jobs only: Denormalizable::DenormalizeAssociationAsyncJob do
          agent.update!(name: 'CAA')
        end

        expect(contract.reload.agent_name).to eq 'CAA'
      end
    end

    context 'without a resolvable inverse' do
      temporary_table :books do |t|
        t.references :publisher
        t.string :agent_name
        t.timestamps
      end

      temporary_model :publisher do
        has_one :agent, as: :client
        has_many :books, inverse_of: false
      end

      temporary_model :book do
        belongs_to :publisher
      end

      temporary_model :agent do
        include Denormalizable::Model

        belongs_to :client, polymorphic: true

        denormalizes :name, to: :books, through: :client, as: :agent_name
      end

      it 'should raise when no inverse association is resolvable' do
        publisher = Publisher.create!(name: 'Penguin')

        expect { Agent.create!(client: publisher, name: 'WME') }.to raise_error Denormalizable::InverseAssociationNotFoundError
      end
    end
  end
end
