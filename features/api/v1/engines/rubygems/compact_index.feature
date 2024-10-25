@api/v1
Feature: Rubygems compact index
  Background:
    Given the following "accounts" exist:
      | id                                   | slug  | name   |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | test1 | Test 1 |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | test2 | Test 2 |
    And the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code  |
      | 1740e334-9d88-43c8-8b2e-38fd98f153d2 | JRUBY |
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
      | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.2 | beta     | PUBLISHED |              |
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
      | 346bd7fd-79fa-4ede-ac55-3ea07ed4cab2 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0-beta.1.gem | gem      |          | be97407d3bf1a66a48903f69335107c6bbf488acddd06bae4d12e7752e09c8a7 | UPLOADED |
      | c8aa34a7-3925-479b-9785-ada9a3736867 | f36515f2-e907-40a3-ac81-2cc1042f8ec9 | bar-1.0.0-beta.2.gem | gem      |          | 1502b2e5bd9414ba8798d596b84cca6c766b7881c3a4493970cc9a3d20acd9e7 | UPLOADED |
      | b95ec07b-1210-4ddc-920e-6008a5c8ed3c | 56f66b77-f447-4300-828b-5cf92e457376 | bar-1.0.0-beta.3.gem | gem      |          | 4a98a6ed4fe4723ca1ba18e52d4c832fb2a1f343e7d9a4c07723a1d41d62c374 | UPLOADED |
      | 9b0fa689-36c3-4b1f-be82-382238a2c5d0 | 0b5bb946-7346-448b-90a0-e8bbc02570e2 | baz-1.0.0.gem        | gem      |          | 5a9fe4919e0d7089020f087561fb3a1fbdcbe420cdb822039f849925aaeaddfd | UPLOADED |
      | b6049631-dac8-49b6-a923-78f022cb1dbe | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.gem        | gem      |          | b6bbb379c7375cfa2bb1384b90afab001baa307e788c55c773fb9ee0d093f707 | UPLOADED |
      | df4474cb-2a7b-4f75-8f27-2b99320e0164 | 00c9c981-8a75-494b-9207-71a829665729 | qux-1.0.0.gem        | gem      |          | e9af40c7b7186b7b45f26990b2be4cf8acb8215abd312e7c1ccfdd66ce5ebb39 | UPLOADED |
      | f52378c0-1d1c-45f6-bff3-3231a99dfb27 | e00475de-edcc-4571-adec-5ef1b91ddb85 | qux-1.0.1.gem        | gem      | ruby     |                                                                  | WAITING  |
      | e7c08c5d-0e1a-439f-8730-3cc5ed8399b9 | d1bb5fca-0afc-4464-b321-4bd45cca8c7a | quxx-1.0.0.gem       | gem      | ruby     | 2a69cc50ecfcbcd8812e452d6a48b4c4bec47855f527ba98c534410a52e1d772 | FAILED   |
      | 5acc0c22-0b7e-43f5-8168-8d341cccbaa6 | 70c40946-4b23-408c-aa1c-fa35421ff46a | quxx-1.1.0.gem       | gem      | ruby     | f200b250b74054f795c396f3981fc515090dd463a96a572375f06b5eaf15da82 | UPLOADED |
      | 22af171a-be06-47b1-bec3-3b2f8974990a | 04d3d9da-4e91-4634-9aa0-41e39a23658c | corge-1.1.0.gem      | gem      |          |                                                                  | UPLOADED |
    And the current account has the following "spec" rows:
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
      Accept: text/plain
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "text/plain" }
      """

  Scenario: Endpoint should only respond to plaintext
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: text/html
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "400"

  Scenario: Endpoint should respond to ping
    When I send a HEAD request to "/accounts/test1/engines/rubygems"
    Then the response status should be "200"

  Scenario: Endpoint should return all gems
    Given I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2,1.0.0-beta.3 a4615843cd8f6a13cbe0796b2d4309ee
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1,1.1.0-java,1.1.0 1629fd7efd26b0d9fe8a71bc82d17f70
      """
    And time is unfrozen

  Scenario: Endpoint should return a gem with dependencies
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      1.1.0-java rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:fa81b56f754533e58ef813e5ce08ad5179b9a51710bfb70082d265e720181793,ruby:>= 3.1
      1.1.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:2202879a9f3995b0bd9572aff97713f029775e364308aa0315233d089e3c66d6,ruby:>= 3.1
      """

  Scenario: Endpoint should return a gem without dependencies
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/bar"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0-beta.1 |checksum:be97407d3bf1a66a48903f69335107c6bbf488acddd06bae4d12e7752e09c8a7
      1.0.0-beta.2 |checksum:1502b2e5bd9414ba8798d596b84cca6c766b7881c3a4493970cc9a3d20acd9e7
      1.0.0-beta.3 |checksum:4a98a6ed4fe4723ca1ba18e52d4c832fb2a1f343e7d9a4c07723a1d41d62c374
      """

  Scenario: Endpoint should return an error for gem without versions
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/qux"
    Then the response status should be "404"

  Scenario: Endpoint should return an error for missing gem
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/x"
    Then the response status should be "404"

  Scenario: Endpoint should return all gem names
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: Product lists available gems (licensed distribution strategy)
    Given I am product "test1" of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2,1.0.0-beta.3 a4615843cd8f6a13cbe0796b2d4309ee
      foo 1.0.0,1.0.1,1.1.0-java,1.1.0 1629fd7efd26b0d9fe8a71bc82d17f70
      """
    And time is unfrozen

  Scenario: Product lists available gems (open distribution strategy)
    Given I am product "test2" of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      """
    And time is unfrozen

  Scenario: Product lists available gem names (open distribution strategy)
    Given I am product "test1" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      foo
      """

  Scenario: Product lists available gem names (open distribution strategy)
    Given I am product "test2" of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      baz
      """

  Scenario: License lists available gems (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1,1.1.0-java,1.1.0 1629fd7efd26b0d9fe8a71bc82d17f70
      """
    And time is unfrozen

  Scenario: License lists available gems (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1 68890f51ad4211d8ef46d47755f23ca1
      """
    And time is unfrozen

  Scenario: License lists available gem names (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: License lists available gem names (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: License retrieves a licensed gem (entitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      1.1.0-java rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:fa81b56f754533e58ef813e5ce08ad5179b9a51710bfb70082d265e720181793,ruby:>= 3.1
      1.1.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:2202879a9f3995b0bd9572aff97713f029775e364308aa0315233d089e3c66d6,ruby:>= 3.1
      """

  Scenario: License retrieves a licensed gem (unentitled)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      """

  Scenario: License retrieves a licensed gem (different product)
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "404"

  Scenario: License retrieves an open gem (different product)
    Given the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/info/baz"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      2.0.0 rack:>= 0|checksum:b6bbb379c7375cfa2bb1384b90afab001baa307e788c55c773fb9ee0d093f707
      """

  Scenario: User lists available gems (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1,1.1.0-java,1.1.0 1629fd7efd26b0d9fe8a71bc82d17f70
      """
    And time is unfrozen

  Scenario: User lists available gems (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1 68890f51ad4211d8ef46d47755f23ca1
      """
    And time is unfrozen

  Scenario: User lists available gems (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1,1.1.0-java,1.1.0 1629fd7efd26b0d9fe8a71bc82d17f70
      """
    And time is unfrozen

  Scenario: User lists available gems (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      bar 1.0.0-beta.1,1.0.0-beta.2 f71117ec6de640251e93cb8cc834838f
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      foo 1.0.0,1.0.1 68890f51ad4211d8ef46d47755f23ca1
      """
    And time is unfrozen

  Scenario: User lists available gems (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    And time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      """
    And time is unfrozen

  Scenario: User lists available gem names (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: User lists available gem names (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: User lists available gem names (with entitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: User lists available gem names (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      bar
      baz
      foo
      """

  Scenario: User lists available gem names (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      baz
      """

  Scenario: User retrieves a licensed gem (with entitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      1.1.0-java rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:fa81b56f754533e58ef813e5ce08ad5179b9a51710bfb70082d265e720181793,ruby:>= 3.1
      1.1.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:2202879a9f3995b0bd9572aff97713f029775e364308aa0315233d089e3c66d6,ruby:>= 3.1
      """

  Scenario: User retrieves a licensed gem (with unentitled owned license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy" and the last "user" as "owner"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      """

  Scenario: User retrieves a licensed gem (with license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      1.1.0-java rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:fa81b56f754533e58ef813e5ce08ad5179b9a51710bfb70082d265e720181793,ruby:>= 3.1
      1.1.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:2202879a9f3995b0bd9572aff97713f029775e364308aa0315233d089e3c66d6,ruby:>= 3.1
      """

  Scenario: User retrieves a licensed gem (with unentitled license)
    Given the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      1.0.0 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:32eae8a165580f793a2fde46dd9ff218bb490ee3d1aeda368dfee7e3726ffb67,ruby:>= 3.1
      1.0.1 rails:>= 7.0,rspec-rails:>= 0,temporary_tables:~> 1.0,sql_matchers:~> 1.0,sqlite3:~> 1.4,mysql2:>= 0,pg:>= 0|checksum:455ec74f7da47f6dc12489c18a0c70ca097613c982751939498e334fba041fc6,ruby:>= 3.1
      """

  Scenario: User retrieves a licensed gem (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "404"

  Scenario: User retrieves an open gem (no license)
    Given the current account has 1 "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/info/baz"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      2.0.0 rack:>= 0|checksum:b6bbb379c7375cfa2bb1384b90afab001baa307e788c55c773fb9ee0d093f707
      """

  Scenario: Anon lists available gems
    Given time is frozen at "2024-10-22T00:00:00.000Z"
    When I send a GET request to "/accounts/test1/engines/rubygems/versions"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      created_at: 2024-10-22T00:00:00Z
      ---
      baz 2.0.0 3b77ccd76cd925a731ecc9d7054d5706
      """
    And time is unfrozen

  Scenario: Anon lists available gem names
    When I send a GET request to "/accounts/test1/engines/rubygems/names"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      baz
      """

  Scenario: Anon retrieves a closed gem
    When I send a GET request to "/accounts/test1/engines/rubygems/info/corge"
    Then the response status should be "404"

  Scenario: Anon retrieves a licensed gem
    When I send a GET request to "/accounts/test1/engines/rubygems/info/foo"
    Then the response status should be "404"

  Scenario: Anon retrieves an open gem
    When I send a GET request to "/accounts/test1/engines/rubygems/info/baz"
    Then the response status should be "200"
    And the response body should be a text document with the following content:
      """
      ---
      2.0.0 rack:>= 0|checksum:b6bbb379c7375cfa2bb1384b90afab001baa307e788c55c773fb9ee0d093f707
      """
