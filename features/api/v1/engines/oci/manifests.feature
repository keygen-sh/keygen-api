@api/v1
@ee
Feature: OCI image manifests
  Background:
    Given the following "accounts" exist:
      | id                                   | slug      | name      |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | linux     | Linux     |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | keygen    | Keygen    |
      | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | microsoft | Microsoft |
    And the following "entitlements" exist:
      | id                                   | account_id                           | code    |
      | 1740e334-9d88-43c8-8b2e-38fd98f153d2 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | INSIDER |
    And the following "products" exist:
      | id                                   | account_id                           | code    | name         | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | alpine  | Alpine Linux | OPEN                  |
      | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | ubuntu  | Ubuntu Linux | LICENSED              |
      | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | keygen  | Keygen       | LICENSED              |
      | b753b26a-836a-410f-9b3d-74a95d27dbc0 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | windows | Windows      | CLOSED                |
    And the following "packages" exist:
      | id                                   | account_id                           | product_id                           | engine | key       | created_at               | updated_at               |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 6198261a-48b5-4445-a045-9fed4afc7735 | oci    | alpine    | 2024-11-01T01:23:45.000Z | 2024-11-01T01:23:45.000Z |
      | ba6a3950-4f18-468f-97af-8706f84d5bfb | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | oci    | ubuntu    | 2024-11-02T01:23:45.000Z | 2024-11-02T01:23:45.000Z |
      | a81a0707-7ef2-417e-8597-ebedba6508ac | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | oci    | api       | 2024-11-0T001:23:45.000Z | 2024-11-03T01:23:45.000Z |
      | 09b859da-d026-414e-a5c0-3ac756da706c | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | b753b26a-836a-410f-9b3d-74a95d27dbc0 | oci    | windows   | 2024-11-0T001:23:45.000Z | 2024-11-03T01:23:45.000Z |
    And the following "releases" exist:
      | id                                   | account_id                           | product_id                           | release_package_id                   | version             | channel  | tag      | status    | entitlements |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 3.20.3              | stable   | 3.20     | PUBLISHED |              |
      | 07b67f68-c88c-4d57-897f-f443adf43be9 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 3.20.4              | stable   |          | DRAFT     |              |
      | d10fc144-c859-4d29-a809-645ada7065ef | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 3.20.5              | stable   |          | YANKED    |              |
      | b180e2fd-49b1-4ace-8a5f-bdea2eb188db | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | ba6a3950-4f18-468f-97af-8706f84d5bfb | 22.04.0             | stable   | jammy    | PUBLISHED |              |
      | a6a6d11d-d456-4a27-bade-90579d4cdf47 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | ba6a3950-4f18-468f-97af-8706f84d5bfb | 24.10.0             | stable   | oracular | PUBLISHED |              |
      | 81d5e2fd-9b10-4995-802b-f54425551211 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 54dbf634-ba9a-44ca-9f2d-f69405bb139c | ba6a3950-4f18-468f-97af-8706f84d5bfb | 24.10.1             | stable   |          | DRAFT     |              |
      | c5efaaed-f13d-411f-bf6e-4a4706ca3010 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | a81a0707-7ef2-417e-8597-ebedba6508ac | 1.4.1               | stable   |          | PUBLISHED |              |
      | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | a81a0707-7ef2-417e-8597-ebedba6508ac | 1.4.0               | stable   |          | PUBLISHED | INSIDER      |
      | 743f1204-c91a-41b6-86e0-07a5fce716d3 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | a81a0707-7ef2-417e-8597-ebedba6508ac | 1.3.0               | stable   | latest   | PUBLISHED |              |
      | 7a5e615a-7814-4ca5-9163-66231d54ab73 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 1c59ac75-35ba-4752-ab69-9fd379a958b8 | a81a0707-7ef2-417e-8597-ebedba6508ac | 1.2.0               | stable   |          | YANKED    |              |
      | 129d6a87-2656-4b26-af56-669a67bd0ff8 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | b753b26a-836a-410f-9b3d-74a95d27dbc0 | 09b859da-d026-414e-a5c0-3ac756da706c | 26100.2314.0-beta.1 | beta     |          | DRAFT     |              |
      | d08b8b81-ae2b-49f7-a9c2-442f89b327b4 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | b753b26a-836a-410f-9b3d-74a95d27dbc0 | 09b859da-d026-414e-a5c0-3ac756da706c | 26100.2314.0        | stable   | 24H2     | PUBLISHED |              |
      | 718ebcd7-dbb8-4f0f-8acf-c24a1ab6be2f | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | b753b26a-836a-410f-9b3d-74a95d27dbc0 | 09b859da-d026-414e-a5c0-3ac756da706c | 26100.2314.0-rc.1   | rc       |          | YANKED    |              |
    And the following "artifacts" exist:
      | id                                   | account_id                           | release_id                           | filename            | filetype | filesize | platform | arch  | checksum                                                         | status     | created_at               | updated_at               |
      | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 757e0a41-835e-42ad-bad8-84cabd29c72a | alpine-3.20.3.tar   | tar      | 3635712  | linux    | amd64 | 6eeecd121962ee55afff1e041f3e52a943a3fae6ccc68e0e156985ea2c43a4ae | UPLOADED   | 2024-11-11T10:26:00.000Z | 2024-11-11T10:26:00.000Z |
      | 6811b0ec-f00c-439c-8310-5569c21e3841 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 07b67f68-c88c-4d57-897f-f443adf43be9 | alpine-3.20.4.tar   | tar      |          | linux    | amd64 | 556d6e61d6342911d62b0fb833f4fe9f51534de8c5258706cda880da07ea71b9 | FAILED     | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      | c2c97ce0-377e-48eb-a895-5bb72cffe99d | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 07b67f68-c88c-4d57-897f-f443adf43be9 | alpine-3.20.4-2.tar | tar      |          | linux    | amd64 |                                                                  | UPLOADED   | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      | f533a413-82d0-47e1-a89a-33b36cfc417a | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | d10fc144-c859-4d29-a809-645ada7065ef | alpine-3.20.5.tar   | tar      |          | linux    | amd64 |                                                                  | UPLOADED   | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      | c557e7f4-80fc-4fa1-bbbc-a8fc1a37a733 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | b180e2fd-49b1-4ace-8a5f-bdea2eb188db | ubuntu-22.04.0.tar  | tar      |          | linux    |       |                                                                  | UPLOADED   | 2024-10-19T00:04:00.000Z | 2024-10-19T00:04:00.000Z |
      | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | a6a6d11d-d456-4a27-bade-90579d4cdf47 | ubuntu-24.10.0.tar  | tar      |          | linux    |       |                                                                  | UPLOADED   | 2024-10-19T00:05:00.000Z | 2024-10-19T00:05:00.000Z |
      | f6ca6c81-2921-4d9b-9165-db8cef975154 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 81d5e2fd-9b10-4995-802b-f54425551211 | ubuntu-24.10.1.tar  | tar      |          | linux    |       | 37ff599634695e61549a5d050f4a08c58b2087d5f293fae9d7a7b787d870741c | WAITING    | 2024-11-15T00:05:00.000Z | 2024-11-15T00:05:00.000Z |
      | 020763a0-1581-482f-b3b0-496c6d1a3bc2 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | c5efaaed-f13d-411f-bf6e-4a4706ca3010 | keygen-1.4.1.tar    | tar      |          | linux    |       |                                                                  | PROCESSING | 2024-11-15T11:11:00.000Z | 2024-11-15T11:11:00.000Z |
      | 89d95ffe-7785-465a-bc26-2da411fe6e99 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | keygen-1.4.0.tar    | tar      |          | linux    |       |                                                                  | UPLOADED   | 2024-11-15T00:00:01.000Z | 2024-11-15T00:00:01.000Z |
      | b33a6df6-91af-4b0a-8c0b-a383befe1dea | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 743f1204-c91a-41b6-86e0-07a5fce716d3 | keygen-1.3.0.tar    | tar      |          | linux    |       |                                                                  | UPLOADED   | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | ecdefa87-85f0-49ad-bb22-be24c9872d0f | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 7a5e615a-7814-4ca5-9163-66231d54ab73 | keygen-1.2.0.tar    | tar      |          | linux    |       |                                                                  | YANKED     | 2024-01-20T11:11:00.000Z | 2024-01-20T11:11:00.000Z |
      | 2e8fc5fb-a57f-49e2-9484-77bb421dc758 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 129d6a87-2656-4b26-af56-669a67bd0ff8 | windows.tar         | tar      |          | windows  |       |                                                                  | UPLOADED   | 2024-11-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
      | f789aaf5-3901-4ce4-9478-3756ad7f7500 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | d08b8b81-ae2b-49f7-a9c2-442f89b327b4 | windows-24H2.tar    | tar      |          | windows  |       |                                                                  | UPLOADED   | 2024-10-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
      | 2da1858d-49eb-47e0-94cc-a94a0bba9453 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 718ebcd7-dbb8-4f0f-8acf-c24a1ab6be2f | windows.tar         | tar      |          | windows  |       |                                                                  | UPLOADED   | 2024-12-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
    And the following "manifests" exist:
      | id                                   | account_id                           | release_artifact_id                  | release_id                           | content_path                                                                  | content_type                                              | content_digest                                                          | content_length | content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | created_at               | updated_at               |
      # alpine 3.20.3
      | 291c9d4c-01b4-4068-b97c-2ac69a6fbeb9 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d | application/vnd.docker.distribution.manifest.list.v2+json | sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d | 1853           | {"manifests":[{"digest":"sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"amd64","os":"linux"},"size":528},{"digest":"sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"arm","os":"linux","variant":"v6"},"size":528},{"digest":"sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"arm","os":"linux","variant":"v7"},"size":528},{"digest":"sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"arm64","os":"linux","variant":"v8"},"size":528},{"digest":"sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"386","os":"linux"},"size":528},{"digest":"sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"ppc64le","os":"linux"},"size":528},{"digest":"sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"riscv64","os":"linux"},"size":528},{"digest":"sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d","mediaType":"application\/vnd.docker.distribution.manifest.v2+json","platform":{"architecture":"s390x","os":"linux"},"size":528}],"mediaType":"application\/vnd.docker.distribution.manifest.list.v2+json","schemaVersion":2}                                                                                                                                                                                                                                                                                                                                                                                                                    | 2024-11-11T10:26:02.000Z | 2024-11-11T10:26:02.000Z |
      | 810e8078-69dd-4e02-97f8-888d78f0accd | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735 | application/vnd.docker.distribution.manifest.v2+json      | sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735 | 528            | {\n   "schemaVersion": 2,\n   "mediaType": "application/vnd.docker.distribution.manifest.v2+json",\n   "config": {\n      "mediaType": "application/vnd.docker.container.image.v1+json",\n      "size": 1471,\n      "digest": "sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b"\n   },\n   "layers": [\n      {\n         "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",\n         "size": 3623807,\n         "digest": "sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170"\n      }\n   ]\n}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | 2024-11-11T10:26:03.000Z | 2024-11-11T10:26:03.000Z |
      # alpine 3.20.4
      | 4e7f03e8-d15e-4c84-8924-befced893584 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | c2c97ce0-377e-48eb-a895-5bb72cffe99d | 07b67f68-c88c-4d57-897f-f443adf43be9 | blobs/sha256/40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | application/vnd.oci.image.index.v1+json                   | sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | 16             | {"test":"draft"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      # alpine 3.20.5
      | 2c4d0522-6100-4d39-aacb-46e3aa87fe59 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | f533a413-82d0-47e1-a89a-33b36cfc417a | d10fc144-c859-4d29-a809-645ada7065ef | blobs/sha256/07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | application/vnd.oci.image.index.v1+json                   | sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | 17             | {"test":"yanked"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | 2024-11-17T10:26:00.000Z | 2024-11-17T10:26:00.000Z |
      # ubuntu 22.04.0
      # ubuntu 24.10.0
      | 86df6c04-35ad-45dc-933e-4d33d9e260ad | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | blobs/sha256/1ae80023cb591b3ee642fde7bef065a334c1da28fc739c148552e1c70b804616 | application/vnd.oci.image.index.v1+json                   | sha256:1ae80023cb591b3ee642fde7bef065a334c1da28fc739c148552e1c70b804616 | 21             | {"hello":"dimension"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | 2024-10-19T00:05:00.000Z | 2024-10-19T00:05:00.000Z |
      | 87e96e5d-8530-4889-b55e-e72737ff4005 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | blobs/sha256/93a23971a914e5eacbf0a8d25154cda309c3c1c72fbb9914d47c60f3cb681588 | application/vnd.oci.image.manifest.v1+json                | sha256:93a23971a914e5eacbf0a8d25154cda309c3c1c72fbb9914d47c60f3cb681588 | 17             | {"hello":"world"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # keygen 1.4.0
      | 22a36ef8-a557-4b5d-8a7b-3fc19373b3e5 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 89d95ffe-7785-465a-bc26-2da411fe6e99 | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | blobs/sha256/bc3e1d7a14473a77d5441941bf4ae3fde4e07128dd38978ac7d91d3ca8bfe651 | application/vnd.oci.image.index.v1+json                   | sha256:bc3e1d7a14473a77d5441941bf4ae3fde4e07128dd38978ac7d91d3ca8bfe651 | 20             | {"hello":"universe"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # keygen 1.3.0
      | 9e54ebf5-33f7-4065-80c0-b88275b3cc21 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1 | application/vnd.oci.image.index.v1+json                   | sha256:410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1 | 1609           | {\n  "schemaVersion": 2,\n  "mediaType": "application/vnd.oci.image.index.v1+json",\n  "manifests": [\n    {\n      "mediaType": "application/vnd.oci.image.manifest.v1+json",\n      "digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",\n      "size": 2196,\n      "platform": {\n        "architecture": "amd64",\n        "os": "linux"\n      }\n    },\n    {\n      "mediaType": "application/vnd.oci.image.manifest.v1+json",\n      "digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",\n      "size": 2196,\n      "platform": {\n        "architecture": "arm64",\n        "os": "linux"\n      }\n    },\n    {\n      "mediaType": "application/vnd.oci.image.manifest.v1+json",\n      "digest": "sha256:5003a58c58d300b63dde62d24c40e56f0c12a23127373be0bfce904cfaf6cf46",\n      "size": 566,\n      "annotations": {\n        "vnd.docker.reference.digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",\n        "vnd.docker.reference.type": "attestation-manifest"\n      },\n      "platform": {\n        "architecture": "unknown",\n        "os": "unknown"\n      }\n    },\n    {\n      "mediaType": "application/vnd.oci.image.manifest.v1+json",\n      "digest": "sha256:bec48978b2eb9496715615e4add1fa70f920c328032a370ccb90b588de4eb3de",\n      "size": 566,\n      "annotations": {\n        "vnd.docker.reference.digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",\n        "vnd.docker.reference.type": "attestation-manifest"\n      },\n      "platform": {\n        "architecture": "unknown",\n        "os": "unknown"\n      }\n    }\n  ]\n}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 800df9ff-a355-4354-8291-b964dbf00bdf | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd | application/vnd.oci.image.manifest.v1+json                | sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd | 2196           | {\n  "schemaVersion": 2,\n  "mediaType": "application/vnd.oci.image.manifest.v1+json",\n  "config": {\n    "mediaType": "application/vnd.oci.image.config.v1+json",\n    "digest": "sha256:9ec80051ed72131fe1d3df8d47a29f4f259295267252e9c8d89968410ed26edc",\n    "size": 8939\n  },\n  "layers": [\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:d25f557d7f31bf7acfac935859b5153da41d13c41f2b468d16f729a5b883634f",\n      "size": 3622094\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:fcb16707477d8b1e3de1322a8996261e0fe9e3b6e139a51aeccccd58afa01cf6",\n      "size": 6686032\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:453bd37d6ebb12875a716b8d83bf4fd9b0ffa419d27c545e55d28e79f47efd46",\n      "size": 193\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:8ef1e9289c27a564a5df0923c486967488442cc4ed2d2f25b130591da7073739",\n      "size": 36221419\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:3db7b584f774d489e9b5bdabf9e229a4da5af8bf3bb1ba8c2b742e6231357861",\n      "size": 140\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:f25496d407c3a3193fb44b7e6e409fc95b0503bb76ea6360656081a0cd784ff9",\n      "size": 2654933\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:bb90333d2b9cdeda9d86da6b25dd713f6449716e24d6d656bd49d0cf36493ac0",\n      "size": 46263627\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1",\n      "size": 32\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:f95430b152addc49861bd4277b22df465321b40557fb687de4527bb2585811bb",\n      "size": 748940\n    },\n    {\n      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",\n      "digest": "sha256:b302a583196ce8ed58fab12b74e36dd9eb7e9e13e57636349aa553f5617000fb",\n      "size": 749075\n    }\n  ]\n} | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # keygen 1.2.0
      # windows 26100.2314.0-beta.1
      | 43bf9a9f-4c4e-4cab-98f0-4d68403bba9f | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2e8fc5fb-a57f-49e2-9484-77bb421dc758 | 129d6a87-2656-4b26-af56-669a67bd0ff8 | blobs/sha256/40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | application/vnd.oci.image.index.v1+json                   | sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | 16             | {"test":"draft"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # windows 26100.2314.0
      | 44f862a3-60fa-4111-a2fd-823d96c474f5 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | f789aaf5-3901-4ce4-9478-3756ad7f7500 | d08b8b81-ae2b-49f7-a9c2-442f89b327b4 | blobs/sha256/ca970908644e34be86cfd5b3196a069a365a2b715346d67bfab2a43455ddfb3a | application/vnd.oci.image.index.v1+json                   | sha256:ca970908644e34be86cfd5b3196a069a365a2b715346d67bfab2a43455ddfb3a | 19             | {"hello":"windows"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # windows 26100.2314.0-rc.1
      | c88480b0-e4a6-4af4-850a-aa8a2ddacf46 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2da1858d-49eb-47e0-94cc-a94a0bba9453 | 718ebcd7-dbb8-4f0f-8acf-c24a1ab6be2f | blobs/sha256/07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | application/vnd.oci.image.index.v1+json                   | sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | 17             | {"test":"yanked"}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
    And the following "descriptors" exist:
      | id                                   | account_id                           | release_artifact_id                  | release_id                           | content_path                                                                  | content_type                                              | content_digest                                                          | content_length | created_at               | updated_at               |
      # alpine 3.20.3
      | f9c8c021-ab02-4d8b-abc8-d82af5e34f19 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | index.json                                                                    | application/vnd.oci.image.index.v1+json                   | sha256:355eee6af939abf5ba465c9be69c3b725f8d3f19516ca9644cf2a4fb112fd83b | 441            | 2024-11-11T10:26:01.000Z | 2024-11-11T10:26:01.000Z |
      | 0a58b112-9fa1-429a-a7d7-8a64930da6cc | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d | application/vnd.docker.distribution.manifest.list.v2+json | sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d | 1853           | 2024-11-11T10:26:02.000Z | 2024-11-11T10:26:02.000Z |
      | 91c35ac6-5cb3-47d1-a0d9-547598a6589b | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735 | application/vnd.docker.distribution.manifest.v2+json      | sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735 | 528            | 2024-11-11T10:26:03.000Z | 2024-11-11T10:26:03.000Z |
      | 8cd3c8b4-52a5-4c36-9cfc-fa7bba1d31e7 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-11-11T10:26:04.000Z | 2024-11-11T10:26:04.000Z |
      | 6e70c51b-c3d4-498d-85bf-4adb1ea75848 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170 | application/vnd.docker.image.rootfs.diff.tar.gzip         | sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170 | 3623807        | 2024-11-11T10:26:05.000Z | 2024-11-11T10:26:05.000Z |
      | 4ab57f49-a0e8-45e2-8800-0b9aef049a98 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 5762c549-7f5b-4a73-9873-3acdb1213fe8 | 757e0a41-835e-42ad-bad8-84cabd29c72a | blobs/sha256/91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b | application/vnd.docker.container.image.v1+json            | sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b | 1471           | 2024-11-11T10:26:06.000Z | 2024-11-11T10:26:06.000Z |
      # alpine 3.20.4
      | a9a08b45-85ef-487f-8a41-878992195dfc | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | c2c97ce0-377e-48eb-a895-5bb72cffe99d | 07b67f68-c88c-4d57-897f-f443adf43be9 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      | 4273bb70-cdb7-4cc5-a348-278d79518b99 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | c2c97ce0-377e-48eb-a895-5bb72cffe99d | 07b67f68-c88c-4d57-897f-f443adf43be9 | blobs/sha256/40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | application/vnd.oci.image.index.v1+json                   | sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | 16             | 2024-11-16T10:26:00.000Z | 2024-11-16T10:26:00.000Z |
      # alpine 3.20.5
      | 29e28002-968a-41e4-91c9-04a50a496e06 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | f533a413-82d0-47e1-a89a-33b36cfc417a | d10fc144-c859-4d29-a809-645ada7065ef | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-11-17T10:26:00.000Z | 2024-11-17T10:26:00.000Z |
      | 9ffaaf05-3279-4083-810e-146c32017102 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | f533a413-82d0-47e1-a89a-33b36cfc417a | d10fc144-c859-4d29-a809-645ada7065ef | blobs/sha256/07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | application/vnd.oci.image.index.v1+json                   | sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | 17             | 2024-11-17T10:26:00.000Z | 2024-11-17T10:26:00.000Z |
      # ubuntu 22.04.0
      | a444c6ca-a632-45f2-b085-053c7f776ae1 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | c557e7f4-80fc-4fa1-bbbc-a8fc1a37a733 | b180e2fd-49b1-4ace-8a5f-bdea2eb188db | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-10-19T00:04:00.000Z | 2024-10-19T00:04:00.000Z |
      # ubuntu 24.10.0
      | 638bee01-0158-4793-af26-7dc3a1a642c3 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | index.json                                                                    | application/vnd.oci.image.index.v1+json                   | sha256:e0d9e343ab1a1deeb5de8608fd64116d20f6273ebd0ad1678eedb831bc4a22ff | 1137           | 2024-10-19T00:05:00.000Z | 2024-10-19T00:05:00.000Z |
      | 5532cd0d-ba1e-4185-8b29-e2787def7ad8 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-10-19T00:05:00.000Z | 2024-10-19T00:05:00.000Z |
      | 9d691418-af60-440d-8425-c7667d149d22 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | blobs/sha256/1ae80023cb591b3ee642fde7bef065a334c1da28fc739c148552e1c70b804616 | application/vnd.oci.image.index.v1+json                   | sha256:1ae80023cb591b3ee642fde7bef065a334c1da28fc739c148552e1c70b804616 | 21             | 2024-10-19T00:05:00.000Z | 2024-10-19T00:05:00.000Z |
      | 8f1ac175-3cf3-4bcf-9f42-b582ed1d9d25 | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | 74ad090a-7cee-4227-96bc-4af939e8bfa7 | a6a6d11d-d456-4a27-bade-90579d4cdf47 | blobs/sha256/93a23971a914e5eacbf0a8d25154cda309c3c1c72fbb9914d47c60f3cb681588 | application/vnd.oci.image.index.v1+json                   | sha256:93a23971a914e5eacbf0a8d25154cda309c3c1c72fbb9914d47c60f3cb681588 | 17             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # keygen 1.4.0
      | 04918f24-376f-40b2-a1a1-5e72de5aac8f | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 89d95ffe-7785-465a-bc26-2da411fe6e99 | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | index.json                                                                    | application/vnd.oci.image.index.v1+json                   | sha256:63179218e5dab1bc90d0580256c5a3bf3b117de72c65d1841d49b283934b2179 | 415            | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 3cc5d2d9-e92c-47b6-a680-0407bde2ced6 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 89d95ffe-7785-465a-bc26-2da411fe6e99 | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-11-15T00:00:01.000Z | 2024-11-15T00:00:01.000Z |
      | e72c7e76-2360-4149-b083-98f5fa08b789 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | 89d95ffe-7785-465a-bc26-2da411fe6e99 | ce73cc94-6d9b-4cc9-a974-3ca738b7b655 | blobs/sha256/bc3e1d7a14473a77d5441941bf4ae3fde4e07128dd38978ac7d91d3ca8bfe651 | application/vnd.oci.image.index.v1+json                   | sha256:bc3e1d7a14473a77d5441941bf4ae3fde4e07128dd38978ac7d91d3ca8bfe651 | 20             | 2024-11-15T00:00:01.000Z | 2024-11-15T00:00:01.000Z |
      # keygen 1.3.0
      | a353caf7-37ba-46a2-bf31-d6c535de4300 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | index.json                                                                    | application/vnd.oci.image.index.v1+json                   | sha256:0262f48d059aa7c5c9da8629569cb732e4a7482da063f0f2ec4abd69ec67c711 | 415            | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 21e01f7a-1900-41ca-8f5f-76917ffdf84a | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1 | application/vnd.oci.image.index.v1+json                   | sha256:410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1 | 1609           | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | b7a2c50f-4953-4364-9f99-165cb3593b96 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd | application/vnd.oci.image.manifest.v1+json                | sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd | 2196           | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | a660e1b4-4056-4a2e-ad03-c6a01da7f394 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | c9d06fb1-9d30-46ad-affc-5bdd06198b61 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/9ec80051ed72131fe1d3df8d47a29f4f259295267252e9c8d89968410ed26edc | application/vnd.oci.image.config.v1+json                  | sha256:9ec80051ed72131fe1d3df8d47a29f4f259295267252e9c8d89968410ed26edc | 8939           | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 79021e97-d012-47cc-b604-9c9336946cde | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/d25f557d7f31bf7acfac935859b5153da41d13c41f2b468d16f729a5b883634f | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:d25f557d7f31bf7acfac935859b5153da41d13c41f2b468d16f729a5b883634f | 3622094        | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 874c970b-d0d2-4968-9f70-7c690dedcab4 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/fcb16707477d8b1e3de1322a8996261e0fe9e3b6e139a51aeccccd58afa01cf6 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:fcb16707477d8b1e3de1322a8996261e0fe9e3b6e139a51aeccccd58afa01cf6 | 6686032        | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | b0831524-5a4b-42d7-ae1e-0f3037aabe89 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/453bd37d6ebb12875a716b8d83bf4fd9b0ffa419d27c545e55d28e79f47efd46 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:453bd37d6ebb12875a716b8d83bf4fd9b0ffa419d27c545e55d28e79f47efd46 | 193            | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | d9e213f2-aba6-4a9d-b024-cce45dd25627 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/8ef1e9289c27a564a5df0923c486967488442cc4ed2d2f25b130591da7073739 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:8ef1e9289c27a564a5df0923c486967488442cc4ed2d2f25b130591da7073739 | 36221419       | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 8a66467e-5a0a-44f1-a26d-763bca4169e2 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/3db7b584f774d489e9b5bdabf9e229a4da5af8bf3bb1ba8c2b742e6231357861 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:3db7b584f774d489e9b5bdabf9e229a4da5af8bf3bb1ba8c2b742e6231357861 | 140            | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 45135e54-c630-4023-bb3c-840a5d0a7c75 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/f25496d407c3a3193fb44b7e6e409fc95b0503bb76ea6360656081a0cd784ff9 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:f25496d407c3a3193fb44b7e6e409fc95b0503bb76ea6360656081a0cd784ff9 | 2654933        | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | ae8e58e7-e14c-47d4-9868-628e9117f2d7 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/bb90333d2b9cdeda9d86da6b25dd713f6449716e24d6d656bd49d0cf36493ac0 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:bb90333d2b9cdeda9d86da6b25dd713f6449716e24d6d656bd49d0cf36493ac0 | 46263627       | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | be8c5f2f-2afc-4a3b-93d0-4dd09fa62cd2 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 | 32             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 1c3e13ea-45ca-4df8-b564-453be0a22351 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/f95430b152addc49861bd4277b22df465321b40557fb687de4527bb2585811bb | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:f95430b152addc49861bd4277b22df465321b40557fb687de4527bb2585811bb | 748940         | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      | 210ebaa8-4c5e-43b0-a6f7-10b8ef171fb8 | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | b33a6df6-91af-4b0a-8c0b-a383befe1dea | 743f1204-c91a-41b6-86e0-07a5fce716d3 | blobs/sha256/b302a583196ce8ed58fab12b74e36dd9eb7e9e13e57636349aa553f5617000fb | application/vnd.oci.image.layer.v1.tar+gzip               | sha256:b302a583196ce8ed58fab12b74e36dd9eb7e9e13e57636349aa553f5617000fb | 749075         | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # keygen 1.2.0
      | 5a2c5246-cc20-49c1-a24c-bca3bf6cfe6a | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | ecdefa87-85f0-49ad-bb22-be24c9872d0f | 7a5e615a-7814-4ca5-9163-66231d54ab73 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-01-20T11:11:00.000Z | 2024-01-20T11:11:00.000Z |
      # windows 26100.2314.0-beta.1
      | b70d742c-2e14-43e4-a6e6-291260430db5 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2e8fc5fb-a57f-49e2-9484-77bb421dc758 | 129d6a87-2656-4b26-af56-669a67bd0ff8 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-10-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
      | 42cadf78-7105-4275-9f61-92ac5510bb20 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2e8fc5fb-a57f-49e2-9484-77bb421dc758 | 129d6a87-2656-4b26-af56-669a67bd0ff8 | blobs/sha256/40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | application/vnd.oci.image.index.v1+json                   | sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229 | 16             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # windows 26100.2314.0
      | aec6088d-f095-4d71-8206-ad55ef5ae03d | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | f789aaf5-3901-4ce4-9478-3756ad7f7500 | d08b8b81-ae2b-49f7-a9c2-442f89b327b4 | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-10-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
      | cd3fb54c-9e79-44ce-8f09-d10349922243 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | f789aaf5-3901-4ce4-9478-3756ad7f7500 | d08b8b81-ae2b-49f7-a9c2-442f89b327b4 | blobs/sha256/ca970908644e34be86cfd5b3196a069a365a2b715346d67bfab2a43455ddfb3a | application/vnd.oci.image.index.v1+json                   | sha256:ca970908644e34be86cfd5b3196a069a365a2b715346d67bfab2a43455ddfb3a | 19             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
      # windows 26100.2314.0-rc.1
      | bfed0766-b2f2-4ec6-b12d-a0617a838734 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2da1858d-49eb-47e0-94cc-a94a0bba9453 | 718ebcd7-dbb8-4f0f-8acf-c24a1ab6be2f | oci-layout                                                                    | application/vnd.oci.layout.header.v1+json                 | sha256:18f0797eab35a4597c1e9624aa4f15fd91f6254e5538c1e0d193b2a95dd4acc6 | 30             | 2024-10-01T00:00:01.000Z | 2024-11-12T00:00:01.000Z |
      | fe28d6c5-0163-4a46-b6d5-7978b8b31958 | 9f3d711d-55ea-49ed-9155-9acf4e4a347b | 2da1858d-49eb-47e0-94cc-a94a0bba9453 | 718ebcd7-dbb8-4f0f-8acf-c24a1ab6be2f | blobs/sha256/07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | application/vnd.oci.image.index.v1+json                   | sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15 | 17             | 2024-06-18T02:52:00.000Z | 2024-06-18T02:52:00.000Z |
    And I send the following raw headers:
      """
      User-Agent: docker/27.0.3 go/go1.21.11 git-commit/662f78c kernel/5.15.153.1-microsoft-standard-WSL2 os/linux arch/amd64 containerd-client/1.7.18+unknown storage-driver/overlayfs UpstreamClient(Docker-Client/27.0.3 \(linux\))
      Accept: */*
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the current account is "linux"
    And the account "linux" is canceled
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "403"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2/linux/alpine/manifests/3.20.3"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "//oci.pkg.keygen.sh/v2/alpine/manifests/3.20.3"
    Then the response status should be "200"

  @mp
  Scenario: Endpoint should pass manifest ack
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a HEAD request to "//oci.pkg.keygen.sh/v2/linux/alpine/manifests/3.20.3"
    Then the response status should be "200"

  @mp
  Scenario: Endpoint should fail manifest ack
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a HEAD request to "//oci.pkg.keygen.sh/v2/linux/alpine/manifests/0.0.0"
    Then the response status should be "404"

  @sp
  Scenario: Endpoint should pass manifest ack
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a HEAD request to "//oci.pkg.keygen.sh/v2/alpine/manifests/3.20.3"
    Then the response status should be "200"

  @sp
  Scenario: Endpoint should fail manifest ack
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a HEAD request to "//oci.pkg.keygen.sh/v2/alpine/manifests/0.0.0"
    Then the response status should be "404"

  Scenario: Endpoint should respond with a matching media type (manifest list)
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.list.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """

  Scenario: Endpoint should respond with a matching media type (manifest)
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.v2+json
      """

  Scenario: Endpoint should respond with any media type
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: text/html, */*
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """

  Scenario: Endpoint should not respond with an unknown media type
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: text/html
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "404"
    And the response should contain the following raw headers:
      """
      Content-Type: application/json; charset=utf-8
      """

  Scenario: Endpoint should return an image index by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.list.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Endpoint should return an image index by tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.list.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Endpoint should return an image index by digest (no redirect)
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Endpoint should return an image manifest list by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.list.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Endpoint should return an image manifest list by tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.list.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Endpoint should return an image manifest list by digest
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.list.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

   Scenario: Endpoint should return an image manifest by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
        "config": {
          "mediaType": "application/vnd.docker.container.image.v1+json",
          "size": 1471,
          "digest": "sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b"
        },
        "layers": [
          {
            "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
            "size": 3623807,
            "digest": "sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170"
          }
        ]
      }
      """

  Scenario: Endpoint should return an image manifest by tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.distribution.manifest.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
        "config": {
          "mediaType": "application/vnd.docker.container.image.v1+json",
          "size": 1471,
          "digest": "sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b"
        },
        "layers": [
          {
            "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
            "size": 3623807,
            "digest": "sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170"
          }
        ]
      }
      """

  Scenario: Endpoint should return an image manifest by digest
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Content-Type: application/vnd.docker.distribution.manifest.v2+json
      """
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
        "config": {
          "mediaType": "application/vnd.docker.container.image.v1+json",
          "size": 1471,
          "digest": "sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b"
        },
        "layers": [
          {
            "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
            "size": 3623807,
            "digest": "sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170"
          }
        ]
      }
      """

  Scenario: Endpoint should return an image config by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.container.image.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "404"

  Scenario: Endpoint should return an image config by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.container.image.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "404"

  Scenario: Endpoint should return an image layer by tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.image.rootfs.diff.tar.gzip
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20"
    Then the response status should be "404"

  Scenario: Endpoint should not return an image config by digest
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:91ef0af61f39ece4d6710e465df5ed6ca12112358344fd51ae6a3b886634148b"
    Then the response status should be "404"

  Scenario: Endpoint should return an image layer by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.image.rootfs.diff.tar.gzip
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "404"

  Scenario: Endpoint should return an image config by version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.container.image.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "404"

  Scenario: Endpoint should return an image layer by tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/vnd.docker.image.rootfs.diff.tar.gzip
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20"
    Then the response status should be "404"

  Scenario: Endpoint should not return an image layer by digest
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:43c4264eed91be63b206e17d93e75256a6097070ce643c5e8f0379998b44f170"
    Then the response status should be "404"

  Scenario: Endpoint should not return an invalid package
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/invalid/manifests/1.2.3"
    Then the response status should be "404"

  Scenario: Endpoint should not return an invalid version
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/0.0.0"
    Then the response status should be "404"

  Scenario: Endpoint should not return an invalid tag
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/invalid"
    Then the response status should be "404"

  Scenario: Endpoint should not return an invalid digest
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:invalid"
    Then the response status should be "404"

  Scenario: Endpoint should support etags (match)
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"c2eab43acb840126ba7a214819e2c71a"
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given the current account is "linux"
    And I am an admin of account "linux"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"c2eab43acb840126ba7a214819e2c71a"
      Cache-Control: max-age=600, private, no-transform
      """

  Scenario: Product retrieves their licensed manifest
    Given the current account is "linux"
    And I am product "ubuntu" of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "dimension" }
      """

  Scenario: Product retrieves their draft manifest
    Given the current account is "microsoft"
    And I am product "windows" of account "microsoft"
    And I use an authentication token
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "test": "draft" }
      """

  Scenario: Product retrieves their yanked manifest
    Given the current account is "microsoft"
    And I am product "windows" of account "microsoft"
    And I use an authentication token
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "test": "yanked" }
      """

  Scenario: Product retrieves their open manifest
    Given the current account is "linux"
    And I am product "alpine" of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Product retrieves another product's licensed manifest
    Given the current account is "linux"
    And I am product "alpine" of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "403"

  Scenario: Product retrieves another product's open manifest
    Given the current account is "linux"
    And I am product "ubuntu" of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request",
        "code": "DENIED"
      }
      """

  Scenario: Product retrieves another account's open manifest
    Given the current account is "keygen"
    And I am product "keygen" of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "401"

  Scenario: License retrieves a manifest for their product by digest
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.manifest.v1+json
      """
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "config": {
          "mediaType": "application/vnd.oci.image.config.v1+json",
          "digest": "sha256:9ec80051ed72131fe1d3df8d47a29f4f259295267252e9c8d89968410ed26edc",
          "size": 8939
        },
        "layers": [
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:d25f557d7f31bf7acfac935859b5153da41d13c41f2b468d16f729a5b883634f",
            "size": 3622094
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:fcb16707477d8b1e3de1322a8996261e0fe9e3b6e139a51aeccccd58afa01cf6",
            "size": 6686032
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:453bd37d6ebb12875a716b8d83bf4fd9b0ffa419d27c545e55d28e79f47efd46",
            "size": 193
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:8ef1e9289c27a564a5df0923c486967488442cc4ed2d2f25b130591da7073739",
            "size": 36221419
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:3db7b584f774d489e9b5bdabf9e229a4da5af8bf3bb1ba8c2b742e6231357861",
            "size": 140
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:f25496d407c3a3193fb44b7e6e409fc95b0503bb76ea6360656081a0cd784ff9",
            "size": 2654933
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:bb90333d2b9cdeda9d86da6b25dd713f6449716e24d6d656bd49d0cf36493ac0",
            "size": 46263627
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1",
            "size": 32
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:f95430b152addc49861bd4277b22df465321b40557fb687de4527bb2585811bb",
            "size": 748940
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:b302a583196ce8ed58fab12b74e36dd9eb7e9e13e57636349aa553f5617000fb",
            "size": 749075
          }
        ]
      }
      """

  Scenario: License retrieves a draft manifest for their product
    Given the current account is "linux"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229"
    Then the response status should be "404"

  Scenario: License retrieves a yanked manifest for their product
    Given the current account is "linux"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15"
    Then the response status should be "404"

  Scenario: License retrieves a manifest for their product (unentitled)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.4.0"
    Then the response status should be "403"

  Scenario: License retrieves a manifest for their product (entitled)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "keygen"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.manifest.v1+json
      """
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.3.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.manifest.v1+json",
        "config": {
          "mediaType": "application/vnd.oci.image.config.v1+json",
          "digest": "sha256:9ec80051ed72131fe1d3df8d47a29f4f259295267252e9c8d89968410ed26edc",
          "size": 8939
        },
        "layers": [
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:d25f557d7f31bf7acfac935859b5153da41d13c41f2b468d16f729a5b883634f",
            "size": 3622094
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:fcb16707477d8b1e3de1322a8996261e0fe9e3b6e139a51aeccccd58afa01cf6",
            "size": 6686032
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:453bd37d6ebb12875a716b8d83bf4fd9b0ffa419d27c545e55d28e79f47efd46",
            "size": 193
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:8ef1e9289c27a564a5df0923c486967488442cc4ed2d2f25b130591da7073739",
            "size": 36221419
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:3db7b584f774d489e9b5bdabf9e229a4da5af8bf3bb1ba8c2b742e6231357861",
            "size": 140
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:f25496d407c3a3193fb44b7e6e409fc95b0503bb76ea6360656081a0cd784ff9",
            "size": 2654933
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:bb90333d2b9cdeda9d86da6b25dd713f6449716e24d6d656bd49d0cf36493ac0",
            "size": 46263627
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1",
            "size": 32
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:f95430b152addc49861bd4277b22df465321b40557fb687de4527bb2585811bb",
            "size": 748940
          },
          {
            "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
            "digest": "sha256:b302a583196ce8ed58fab12b74e36dd9eb7e9e13e57636349aa553f5617000fb",
            "size": 749075
          }
        ]
      }
      """

  Scenario: License retrieves a manifest for their product by version
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "world" }
      """

  Scenario: License retrieves a manifest for their product by tag
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/oracular"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "world" }
      """

  Scenario: License retrieves an index for their product by digest
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/sha256:410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.index.v1+json",
        "manifests": [
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
            "size": 2196,
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
            "size": 2196,
            "platform": {
              "architecture": "arm64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:5003a58c58d300b63dde62d24c40e56f0c12a23127373be0bfce904cfaf6cf46",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:bec48978b2eb9496715615e4add1fa70f920c328032a370ccb90b588de4eb3de",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          }
        ]
      }
      """

  Scenario: License retrieves an index for their product (entitled)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-entitlement" for the last "entitlement" and the last "license"
    And I am a license of account "keygen"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.3.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.index.v1+json",
        "manifests": [
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
            "size": 2196,
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
            "size": 2196,
            "platform": {
              "architecture": "arm64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:5003a58c58d300b63dde62d24c40e56f0c12a23127373be0bfce904cfaf6cf46",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:bec48978b2eb9496715615e4add1fa70f920c328032a370ccb90b588de4eb3de",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          }
        ]
      }
      """

  Scenario: License retrieves an index for their product by version
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "dimension" }
      """

  Scenario: License retrieves an index for their product by tag
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    And I send the following raw headers:
      """
      Accept: application/vnd.oci.image.index.v1+json
      """
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/oracular"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "dimension" }
      """

  Scenario: License retrieves a manifest for their closed product
    Given the current account is "microsoft"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "microsoft"
    And I authenticate with my key
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/26100.2314.0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request",
        "code": "DENIED"
      }
      """

  Scenario: License retrieves a manifest for another account's closed product
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/26100.2314.0"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "LICENSE_INVALID"
      }
      """

  Scenario: License retrieves a manifest for another licensed product
    Given the current account is "linux"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request",
        "code": "DENIED"
      }
      """

  Scenario: License retrieves a manifest for another open product
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "linux"
    And I authenticate with my key
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: License retrieves a manifest for another account
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "keygen"
    And I authenticate with my key
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "401"

  Scenario: User retrieves a draft manifest
    Given the current account is "linux"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229"
    Then the response status should be "404"

  Scenario: User retrieves a yanked manifest
    Given the current account is "linux"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15"
    Then the response status should be "404"

  Scenario: User retrieves a manifest (with unentitled owned license)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.4.0"
    Then the response status should be "403"

  Scenario: User retrieves a manifest (with entitled owned license)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the first "license"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.4.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "universe" }
      """

  Scenario: User retrieves a manifest (with unentitled license)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.4.0"
    Then the response status should be "403"

  Scenario: User retrieves a manifest (with entitled license)
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-entitlement" for the first "entitlement" and the last "license"
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.4.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "universe" }
      """

  Scenario: User retrieves a manifest by version
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/24.10.0"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "dimension" }
      """

  Scenario: User retrieves a manifest by tag
    Given the current account is "linux"
    And the current account has 1 "policy" for the second "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/oracular"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      { "hello": "dimension" }
      """

  Scenario: User retrieves a manifest by digest
    Given the current account is "keygen"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "keygen"
    And I use an authentication token
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/sha256:410e8b41faa7b09512984829d2721110f6fbefa9be77ba80162a07e7e0039ec1"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "schemaVersion": 2,
        "mediaType": "application/vnd.oci.image.index.v1+json",
        "manifests": [
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
            "size": 2196,
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
            "size": 2196,
            "platform": {
              "architecture": "arm64",
              "os": "linux"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:5003a58c58d300b63dde62d24c40e56f0c12a23127373be0bfce904cfaf6cf46",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:9c74df62b4d5722f86c31ce8319f047bdced5af0da2e9403fb3154d2599736cd",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          },
          {
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "digest": "sha256:bec48978b2eb9496715615e4add1fa70f920c328032a370ccb90b588de4eb3de",
            "size": 566,
            "annotations": {
              "vnd.docker.reference.digest": "sha256:415654d92c281414cda9931cb7cb13027a5dadc63f8844944c53c6a4888d23d3",
              "vnd.docker.reference.type": "attestation-manifest"
            },
            "platform": {
              "architecture": "unknown",
              "os": "unknown"
            }
          }
        ]
      }
      """

  Scenario: User retrieves a closed manifest (with license)
    Given the current account is "microsoft"
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy" and the last "user" as "owner"
    And I am the last user of account "microsoft"
    And I use an authentication token
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/24H2"
    Then the response status should be "403"

  Scenario: User retrieves a closed manifest (no license)
    Given the current account is "linux"
    And  the current account has 1 "user"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/24H2"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "TOKEN_INVALID"
      }
      """

  Scenario: User retrieves a licensed manifest (no license)
    Given the current account is "linux"
    And  the current account has 1 "user"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/ubuntu/manifests/oracular"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request",
        "code": "DENIED"
      }
      """

  Scenario: User retrieves an open manifest (no license)
    Given the current account is "linux"
    And  the current account has 1 "user"
    And I am the last user of account "linux"
    And I use an authentication token
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """

  Scenario: Anon retrieves a draft manifest
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:40f923622162df3ece7602a0d41ee7920aaf3c978ca9e9f9aa4dc7b34af2e229"
    Then the response status should be "404"

  Scenario: Anon retrieves a yanked manifest
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/sha256:07f83d6bdf77359ea8d23fbb11ae297a9c8f4a85fe0403e34106353b04ae8b15"
    Then the response status should be "404"

  Scenario: Anon retrieves a closed manifest
    When I send a GET request to "/accounts/microsoft/engines/oci/windows/manifests/26100.2314.0"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "UNAUTHORIZED"
      }
      """

  Scenario: Anon retrieves a licensed manifest
    When I send a GET request to "/accounts/keygen/engines/oci/api/manifests/1.3.0"
    Then the response status should be "401"
    And the first error should have the following properties:
      """
      {
        "title": "Unauthorized",
        "detail": "You must be authenticated to complete the request",
        "code": "UNAUTHORIZED"
      }
      """

  Scenario: Anon retrieves an open manifest
    When I send a GET request to "/accounts/linux/engines/oci/alpine/manifests/3.20.3"
    Then the response status should be "200"
    And the response body should be a JSON document with the following content:
      """
      {
        "manifests": [
          {
            "digest": "sha256:33735bd63cf84d7e388d9f6d297d348c523c044410f553bd878c6d7829612735",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "amd64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:50f635c8b04d86dde8a02bcd8d667ba287eb8b318c1c0cf547e5a48ddadea1be",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v6"
            },
            "size": 528
          },
          {
            "digest": "sha256:f2f82d42495723c4dc508fd6b0978a5d7fe4efcca4282e7aae5e00bcf4057086",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm",
              "os": "linux",
              "variant": "v7"
            },
            "size": 528
          },
          {
            "digest": "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "arm64",
              "os": "linux",
              "variant": "v8"
            },
            "size": 528
          },
          {
            "digest": "sha256:b3e87f642f5c48cdc7556c3e03a0d63916bd0055ba6edba7773df3cb1a76f224",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "386",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:c7a6800e3dc569a2d6e90627a2988f2a7339e6f111cdf6a0054ad1ff833e99b0",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "ppc64le",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:80cde017a10529a18a7274f70c687bb07c4969980ddfb35a1b921fda3a020e5b",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "riscv64",
              "os": "linux"
            },
            "size": 528
          },
          {
            "digest": "sha256:2b5b26e09ca2856f50ac88312348d26c1ac4b8af1df9f580e5cf465fd76e3d4d",
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "platform": {
              "architecture": "s390x",
              "os": "linux"
            },
            "size": 528
          }
        ],
        "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
        "schemaVersion": 2
      }
      """
