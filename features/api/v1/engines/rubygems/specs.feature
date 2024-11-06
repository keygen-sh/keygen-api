@api/v1
Feature: Rubygems legacy specs index
  Background:
    Given the following "accounts" exist:
      | id                                   | slug  | name   |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | test1 | Test 1 |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | test2 | Test 2 |
    And the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code  |
      | 1740e334-9d88-43c8-8b2e-38fd98f153d2 | JRUBY |
      | 4cb07bd3-dc2d-4aed-b4e7-6d6b775e0005 | DEV   |
    And the current account has the following "product" rows:
      | id                                   | code  | name   | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | test1 | Test 1 | LICENSED              |
      | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | test2 | Test 2 | OPEN                  |
      | 6727d2a2-626c-4270-880c-3f7f378ea37a | test3 | Test 3 | CLOSED                |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine   | key   |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems | foo   |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems | bar   |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | rubygems | baz   |
      | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | rubygems | qux   |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 | raw      | quxx  |
      | 3d771f82-a0ed-48fd-914a-f5ecda9b4044 | 6727d2a2-626c-4270-880c-3f7f378ea37a | rubygems | corge |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  | status    | entitlements |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   | PUBLISHED |              |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.1        | stable   | PUBLISHED |              |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   | PUBLISHED | JRUBY        |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     | PUBLISHED |              |
      | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.2 | beta     | PUBLISHED | DEV          |
      | 56f66b77-f447-4300-828b-5cf92e457376 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.3 | beta     | DRAFT     |              |
      | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 1.0.0        | stable   | YANKED    |              |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 2.0.0        | stable   | PUBLISHED |              |
      | 00c9c981-8a75-494b-9207-71a829665729 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | 1.0.0        | stable   | PUBLISHED |              |
      | e00475de-edcc-4571-adec-5ef1b91ddb85 | cad3c65c-b6a5-4b3d-bce6-c2280953b8b8 | cd46b4d3-60ab-43e9-b19d-87a9faf13adc | 1.1.0        | stable   | PUBLISHED |              |
      | d1bb5fca-0afc-4464-b321-4bd45cca8c7a | 6198261a-48b5-4445-a045-9fed4afc7735 | 5666d47e-936e-4d48-8dd7-382d32462b4e | 1.0.0        | stable   | PUBLISHED |              |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 5666d47e-936e-4d48-8dd7-382d32462b4e | 1.1.0        | stable   | PUBLISHED |              |
      | 04d3d9da-4e91-4634-9aa0-41e39a23658c | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | 0.0.1        | stable   | PUBLISHED |              |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename             | filetype | platform | checksum                                                         | status   |
      | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.gem        | gem      | ruby     | 32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67 | UPLOADED |
      | ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.gem        | gem      | ruby     | 455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6 | UPLOADED |
      | 92c38af8-7ed7-4adc-aee2-21ceb5c6511c | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0-jruby.gem  | gem      | jruby    | fa81b56f754533e58ef813e5ce08ad5179b9a51710bfb70082d265e720181793 | UPLOADED |
      | 55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.gem        | gem      | ruby     | 2202879a9f3995b0bd9572aff97713f029775e364308aa0315233d089e3c66d6 | UPLOADED |
      | 346bd7fd-79fa-4ede-ac55-3ea07ed4cab2 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0-beta.1.gem | gem      |          | vpdAfTvxpmpIkD9pM1EHxrv0iKzd0GuuTRLndS4JyKc=                     | UPLOADED |
      | c8aa34a7-3925-479b-9785-ada9a3736867 | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | bar-1.0.0-beta.2.gem | gem      |          | FQKy5b2UFLqHmNWWuEzKbHZreIHDpEk5cMyaPSCs2ec=                     | UPLOADED |
      | b95ec07b-1210-4ddc-920e-6008a5c8ed3c | 56f66b77-f447-4300-828b-5cf92e457376 | bar-1.0.0-beta.3.gem | gem      |          | Spim7U/kcjyhuhjlLUyDL7Kh80Pn2aTAdyOh1B1iw3Q=                     | UPLOADED |
      | 9b0fa689-36c3-4b1f-be82-382238a2c5d0 | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | baz-1.0.0.gem        | gem      |          |                                                                  | UPLOADED |
      | b6049631-dac8-49b6-a923-78f022cb1dbe | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.gem        | gem      |          |                                                                  | UPLOADED |
      | df4474cb-2a7b-4f75-8f27-2b99320e0164 | 00c9c981-8a75-494b-9207-71a829665729 | qux-1.0.0.gem        | gem      |          | e9af40c7b7186b7b45f26990b2be4cf8acb8215abd312e7c1ccfdd66ce5ebb39 | UPLOADED |
      | f52378c0-1d1c-45f6-bff3-3231a99dfb27 | e00475de-edcc-4571-adec-5ef1b91ddb85 | qux-1.0.1.gem        | gem      | ruby     |                                                                  | WAITING  |
      | e7c08c5d-0e1a-439f-8730-3cc5ed8399b9 | d1bb5fca-0afc-4464-b321-4bd45cca8c7a | quxx-1.0.0.gem       | gem      | ruby     | 2a69cc50ecfcbcd8812e452d6a48b4c4bec47855f527ba98c534410a52e1d772 | FAILED   |
      | 5acc0c22-0b7e-43f5-8168-8d341cccbaa6 | 70c40946-4b23-408c-aa1c-fa35421ff46a | quxx-1.1.0.gem       | gem      | ruby     | f200b250b74054f795c396f3981fc515090dd463a96a572375f06b5eaf15da82 | UPLOADED |
      | 22af171a-be06-47b1-bec3-3b2f8974990a | 04d3d9da-4e91-4634-9aa0-41e39a23658c | corge-1.1.0.gem      | gem      |          |                                                                  | UPLOADED |
    And the current account has the following "manifest" rows:
      | release_artifact_id                  | release_id                           | content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
      | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | --- !ruby/object:Gem::Specification\nname: foo\nversion: !ruby/object:Gem::Version\n  version: 1.0.0\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies:\n- !ruby/object:Gem::Dependency\n  name: rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n  type: :runtime\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n- !ruby/object:Gem::Dependency\n  name: rspec-rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: temporary_tables\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sql_matchers\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sqlite3\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n- !ruby/object:Gem::Dependency\n  name: mysql2\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: pg\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\ndescription: foo\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses:\n- MIT\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '3.1'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n  |
      | ec49b6bd-a73a-47a3-bd05-f0ecab3b90c0 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | --- !ruby/object:Gem::Specification\nname: foo\nversion: !ruby/object:Gem::Version\n  version: 1.0.1\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies:\n- !ruby/object:Gem::Dependency\n  name: rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n  type: :runtime\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n- !ruby/object:Gem::Dependency\n  name: rspec-rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: temporary_tables\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sql_matchers\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sqlite3\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n- !ruby/object:Gem::Dependency\n  name: mysql2\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: pg\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\ndescription: foo\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses:\n- MIT\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '3.1'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n  |
      | 92c38af8-7ed7-4adc-aee2-21ceb5c6511c | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | --- !ruby/object:Gem::Specification\nname: foo\nversion: !ruby/object:Gem::Version\n  version: 1.1.0\nplatform: jruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies:\n- !ruby/object:Gem::Dependency\n  name: rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n  type: :runtime\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n- !ruby/object:Gem::Dependency\n  name: rspec-rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: temporary_tables\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sql_matchers\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sqlite3\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n- !ruby/object:Gem::Dependency\n  name: mysql2\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: pg\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\ndescription: foo\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses:\n- MIT\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '3.1'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n |
      | 55bba4f4-6494-4a2d-a14e-6b4d6d2d00e8 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | --- !ruby/object:Gem::Specification\nname: foo\nversion: !ruby/object:Gem::Version\n  version: 1.1.0\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies:\n- !ruby/object:Gem::Dependency\n  name: rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n  type: :runtime\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '7.0'\n- !ruby/object:Gem::Dependency\n  name: rspec-rails\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: temporary_tables\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sql_matchers\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.0'\n- !ruby/object:Gem::Dependency\n  name: sqlite3\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - "~>"\n      - !ruby/object:Gem::Version\n        version: '1.4'\n- !ruby/object:Gem::Dependency\n  name: mysql2\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n- !ruby/object:Gem::Dependency\n  name: pg\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :development\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\ndescription: foo\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses:\n- MIT\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '3.1'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n  |
      | 346bd7fd-79fa-4ede-ac55-3ea07ed4cab2 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | --- !ruby/object:Gem::Specification\nname: bar\nversion: !ruby/object:Gem::Version\n  version: 1.0.0-beta.1\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies: []\ndescription: bar\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
      | c8aa34a7-3925-479b-9785-ada9a3736867 | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | --- !ruby/object:Gem::Specification\nname: bar\nversion: !ruby/object:Gem::Version\n  version: 1.0.0-beta.2\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies: []\ndescription: bar\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
      | b95ec07b-1210-4ddc-920e-6008a5c8ed3c | 56f66b77-f447-4300-828b-5cf92e457376 | --- !ruby/object:Gem::Specification\nname: bar\nversion: !ruby/object:Gem::Version\n  version: 1.0.0-beta.3\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies: []\ndescription: bar\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
      | 9b0fa689-36c3-4b1f-be82-382238a2c5d0 | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | --- !ruby/object:Gem::Specification\nname: baz\nversion: !ruby/object:Gem::Version\n  version: 1.0.0\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies: []\ndescription: baz\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
      | b6049631-dac8-49b6-a923-78f022cb1dbe | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | --- !ruby/object:Gem::Specification\nname: baz\nversion: !ruby/object:Gem::Version\n  version: 2.0.0\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies:\n- !ruby/object:Gem::Dependency\n  name: rack\n  requirement: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\n  type: :runtime\n  prerelease: false\n  version_requirements: !ruby/object:Gem::Requirement\n    requirements:\n    - - ">="\n      - !ruby/object:Gem::Version\n        version: '0'\ndescription: baz\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
      | 5acc0c22-0b7e-43f5-8168-8d341cccbaa6 | 70c40946-4b23-408c-aa1c-fa35421ff46a | --- !ruby/object:Gem::Specification\nname: quxx\nversion: !ruby/object:Gem::Version\n  version: 1.1.0\nplatform: ruby\nauthors: []\nautorequire: \nbindir: bin\ncert_chain: []\ndate: 2024-10-22 00:00:00.000000000 Z\ndependencies: []\ndescription: quxx\nemail: \nexecutables: []\nextensions: []\nextra_rdoc_files: []\nfiles: []\nhomepage: \nlicenses: []\nmetadata: {}\npost_install_message: \nrdoc_options: []\nrequire_paths:\n- lib\nrequired_ruby_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequired_rubygems_version: !ruby/object:Gem::Requirement\n  requirements:\n  - - ">="\n    - !ruby/object:Gem::Version\n      version: '0'\nrequirements: []\nrubygems_version: 3.5.11\nsigning_key: \nspecification_version: 4\nsummary: \ntest_files: []\n                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
    And I send the following raw headers:
      """
      User-Agent: Ruby, RubyGems/3.5.11 x86_64-linux Ruby/3.3.4 (2024-07-09 patchlevel 94)
      Accept: application/octet-stream
      """

  # quick gemspec
  Scenario: Endpoint should be inaccessible when account is disabled (quick gemspec)
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/test1/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "200"

  Scenario: Endpoint should return a quick gemspec
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"7881fff6707156380bdc9236e286cf83"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"7881fff6707156380bdc9236e286cf83"
      Cache-Control: max-age=86400, private
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: Endpoint should return an error (not found)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/corge-1.0.0.gemspec.rz"
    Then the response status should be "404"

  Scenario: Product retrieves a gemspec (same product)
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: Product retrieves a gem (different product)
    Given I am product "test2" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.0.gemspec.rz"
    Then the response status should be "404"

  Scenario: License retrieves a licensed gem (same product)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.1.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.1 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.1".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: License retrieves a licensed gem (different product)
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.1.gemspec.rz"
    Then the response status should be "404"

  Scenario: License retrieves an open gem (different product)
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/baz-2.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: baz 2.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "baz".freeze
        s.version = "2.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "baz".freeze
        s.licenses = [[]]
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
      end
      """

  Scenario: User retrieves a licensed gem (with owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.1.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.1 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.1".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: User retrieves a licensed gem (with license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.1.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: foo 1.0.1 ruby lib

      Gem::Specification.new do |s|
        s.name = "foo".freeze
        s.version = "1.0.1".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "foo".freeze
        s.licenses = [["MIT".freeze]]
        s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0".freeze])
        s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<temporary_tables>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sql_matchers>.freeze, ["~> 1.0".freeze])
        s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4".freeze])
        s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
        s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
      end
      """

  Scenario: User retrieves a licensed gem (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/foo-1.0.1.gemspec.rz"
    Then the response status should be "404"

  Scenario: User retrieves an open gem (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/baz-2.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: baz 2.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "baz".freeze
        s.version = "2.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "baz".freeze
        s.licenses = [[]]
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
      end
      """

  Scenario: Anon retrieves a closed gem
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/corge-1.0.0.gemspec.rz"
    Then the response status should be "404"

  Scenario: Anon retrieves a licensed gem
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/bar-1.0.0-beta.2.gemspec.rz"
    Then the response status should be "404"

  Scenario: Anon retrieves an open gem
    When I send a GET request to "/accounts/test1/engines/rubygems/quick/Marshal.4.8/baz-2.0.0.gemspec.rz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be a gemspec with the following content:
      """
      # -*- encoding: utf-8 -*-
      # stub: baz 2.0.0 ruby lib

      Gem::Specification.new do |s|
        s.name = "baz".freeze
        s.version = "2.0.0".freeze

        s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
        s.require_paths = ["lib".freeze]
        s.date = "2024-10-22"
        s.description = "baz".freeze
        s.licenses = [[]]
        s.rubygems_version = "3.5.11".freeze
        s.summary = nil

        s.specification_version = 4

        s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
      end
      """

  # specs
  Scenario: Endpoint should be inaccessible when account is disabled (specs)
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/test1/specs.4.8.gz"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/specs.4.8.gz"
    Then the response status should be "200"

  Scenario: Endpoint should return stable gem specs
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"697c5c065808ab67076f865ec7d72853"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"697c5c065808ab67076f865ec7d72853"
      Cache-Control: max-age=86400, private
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: Product retrieves their stable gem specs
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: License retrieves their stable gem specs (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: License retrieves their stable gem specs (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: User retrieves their stable gem specs (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: User retrieves their stable gem specs (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: User retrieves their stable gem specs (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: User retrieves their stable gem specs (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: Anon retrieves stable gem specs
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"]]
      """

  # latest specs
  Scenario: Endpoint should be inaccessible when account is disabled (latest specs)
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/test1/latest_specs.4.8.gz"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/latest_specs.4.8.gz"
    Then the response status should be "200"

  Scenario: Endpoint should return latest gem specs
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"bb875b8be35a27c3ad8692476c094c79"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"bb875b8be35a27c3ad8692476c094c79"
      Cache-Control: max-age=86400, private
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: Product retrieves their latest gem specs
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: License retrieves their latest gem specs (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: License retrieves their latest gem specs (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: User retrieves their latest gem specs (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: User retrieves their latest gem specs (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: User retrieves their latest gem specs (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.1.0">, "java"], ["foo", #<Gem::Version "1.1.0">, "ruby"]]
      """

  Scenario: User retrieves their latest gem specs (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"], ["foo", #<Gem::Version "1.0.1">, "ruby"]]
      """

  Scenario: Anon retrieves latest gem specs
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["baz", #<Gem::Version "2.0.0">, "ruby"]]
      """

  # prerelease specs
  Scenario: Endpoint should be inaccessible when account is disabled (prerelease specs)
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/test1/prerelease_specs.4.8.gz"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//rubygems.pkg.keygen.sh/prerelease_specs.4.8.gz"
    Then the response status should be "200"

  Scenario: Endpoint should return prerelease gem specs
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.3">, "ruby"]]
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"7e47b8d18320b47af2f1a03d2f75983b"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"7e47b8d18320b47af2f1a03d2f75983b"
      Cache-Control: max-age=86400, private
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.3">, "ruby"]]
      """

  Scenario: Product retrieves their prerelease gem specs
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.3">, "ruby"]]
      """

  Scenario: License retrieves their prerelease gem specs (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the second "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"]]
      """

  Scenario: License retrieves their prerelease gem specs (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"]]
      """

  Scenario: User retrieves their prerelease gem specs (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the second "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"]]
      """

  Scenario: User retrieves their prerelease gem specs (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"]]
      """

  Scenario: User retrieves their prerelease gem specs (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the second "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"], ["bar", #<Gem::Version "1.0.0.pre.beta.2">, "ruby"]]
      """

  Scenario: User retrieves their prerelease gem specs (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      [["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"]]
      """

  Scenario: Anon retrieves prerelease gem specs
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/octet-stream" }
      """
    And the response body should be gemspecs with the following content:
      """
      []
      """
