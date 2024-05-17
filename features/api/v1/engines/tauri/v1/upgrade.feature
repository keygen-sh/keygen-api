@api/v1
Feature: Tauri v1 upgrade application
  Background:
    Given the following "accounts" exist:
      | name   | slug  |
      | Test 1 | test1 |
      | Test 2 | test2 |
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine | key  |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | tauri  | app1 |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | tauri  | app2 |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi   | pkg1 |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 |        | pkg2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  | description |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   | foo         |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   | bar         |
      | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.2.0-beta.1 | beta     |             |
      | c77ba874-de62-4a17-8368-fc10db1e1c80 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     | baz         |
      | 29f74047-265f-452c-9d64-779621682857 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.1-beta.1 | beta     | baz         |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 2.0.0-beta.1 | beta     | qux         |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                  | filetype | platform | arch   | signature                                                                                |
      # 1.0.0
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.AppImage            | appimage | linux    | x86_64 | KhuUa6VkDwE1CxJ37Z2bokP4OCeFDtA457rCoeL3it8zvjlLHw4JB29/OV6mn0cwtcW985kcLxkeD7LmLs7KUw== |
      | 948f9b83-9e0d-469d-8982-e49213efe85e | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.AppImage.tar.gz     | gz       | linux    | x86_64 | /EUsVzHfgst54mhWWb4opT65nre3vL/14sfk8wpxsWiIAc2hLSkWKtnAwxDtO/K/tjXqzoOpKxWNIiXtM9junA== |
      | c1f8705e-68cd-4312-b2b1-72e19df47bd1 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.AppImage.tar.gz.sig | sig      | linux    | x86_64 | PGXlpwysSCW2qsWXwBHeBWAlUP+s0E3mhUufAHpU9IpIjIufWDVbu9/8GTuxCKvElDcq/b59HnwNSDXx4deOLw== |
      | 2fd19ae7-e0cf-4de0-ad4a-1ca65db75c87 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.app                 | app      | darwin   | x86_64 | N7XdIjFjUxsaldjvUiPeTqrMZgcvcx9+DTEslA26iouEcMEwP9Wlc90VHzed+f/V47FpDrPQrUsBjPDcSNPsGw== |
      | a8e49ea6-17df-4798-937f-e4756e331db5 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.app.tar.gz          | gz       | darwin   | x86_64 | d4LD3Wc6/wkAH6ZM+e4a4RYwoCMmsigGDdO8fG8xpywOKtoyE1oE5gJRvaiEpkZ00JsxtJuzfwIov1sQg30KdA== |
      | adce1d8b-7120-43b6-a42a-a64c24ed2a25 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.app.tar.gz.sig      | sig      | darwin   | x86_64 | YDacBfpcurpkoOrDGhpbguhYlwDC7nTuyevwMJTXnwEHbcdO52SJU6bSKgNYHsU4UpYz3ShDG88eL4QtOITSNA== |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-setup.exe           | exe      | windows  | x86_64 | /nYfyW4+9j1i+VcJxmq6wlcVc9JnxvC01OuzvNvVyl8GjmFQpZhjHimcjaGSnc1Jg4y99l33kQhF0Ju3ThZtpQ== |
      | 56277838-ddb5-4c54-a3d2-0fad8bdfefe1 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-setup.nsis.zip      | zip      | windows  | x86_64 | GFnRwU9m6sM7VaoG48wAxFNbAWlSHpG5A8pyiecM6cWVjewJub0Np4uXR3vWQQch5mfRs+C5AITk8PCk5Ns1QQ== |
      | 1cccff81-8b49-40b2-9453-3456f2ca04ac | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-setup.nsis.zip.sig  | sig      | windows  | x86_64 | tOfzZilkppAQWhtT6buV7tZUdzDNOZK1YjNkslSSafzsvsuQmSbk9XfXXQEeF1iSgbM+x8fGlCcTjuBDSZZS1Q== |
      | ab3f9749-3ea7-4057-92ec-d647784ff097 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.msi                 | msi      | windows  | x86_64 | AvUSjpAijmte0EuiWtfj0iajkKqJn11tiKGEomaQzFEqULaAUsoE/aME9akekNnPC3jQp3gu7mHgJvAlwXZBBA== |
      | d7e01e53-4f9c-48a5-96cb-13207fc25cfe | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.msi.zip             | zip      | windows  | x86_64 | 5N6y+NOpxLwwH0AcOHGfXLJWuVdutLKcqhfAHaRnYQXI1ltPbPu7cp7sewYzixoKRsrylnBonitks18aVCt4Qg== |
      | a2fd1960-54c6-4624-83d1-84f0c8dd1f1a | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp.msi.zip.sig         | sig      | windows  | x86_64 | xlHIObWDYsjaYOl1EZEGGfkpi1DlT8/73vkJ2gBdFKQBcPJa4iwI4887vQnfi65fH+s3ptcOjmrtiiRnqTTt4w=  |
      # 1.1.0
      | 00aeec65-165c-487c-8e22-7ab454319b0f | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.AppImage            | appimage | linux    | x86_64 | 93pUF68vzR3QRoGSXHbTQ9XVvXNburu5ofuFFLcrm1C1ZD9C2fr5mcaG06RljftY1HUzlFrpFmk9WVEbwr18tQ== |
      | 6ce09e8b-26e7-4524-a10e-a410fc6580b0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.AppImage.tar.gz     | gz       | linux    | x86_64 | bTm5t7bH2G9o3NAYgd4MGx7/nwnKCd+q4cdelm20tzcEpRepzto0KNmVl7z+AgiOOW6Cxkqyp0/zR2IntMnN7A== |
      | 394180bd-4e0d-4d1b-986d-e4befad92101 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.AppImage.tar.gz.sig | sig      | linux    | x86_64 | Lc4r8JwhtfB7y9AhQ48uQiITGBXeockeMrsZU6kFk9dSF0dAi6SDWCFUsrJbUYPRhN2eduQdk8fHq0GwRD/dgw== |
      | 65132a0a-4ca9-4422-b836-0cd39b0a94f7 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.app                 | app      | darwin   | x86_64 | DrLt7Nc1tqwsPehg5TxG7OKz2qLaDt0F61xPN6KCZjULc8OWVO2m+WAZdDFnzh+edHWtSawYWgwlIUREnYzKmQ== |
      | 77aaaf13-cfc3-4339-8350-163efcaf8814 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.app.tar.gz          | gz       | darwin   | x86_64 | qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw== |
      | 8bdc0604-6948-4ab7-82bc-2b9a19153367 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.app.tar.gz.sig      | sig      | darwin   | x86_64 | AB/jy6vPxiW8grw86W9iDNqV/hrs2NKRakT9shzyJtv6LO9cza5FBoJctzH2B3Z84x5Vq19vwU66QUf5Ac7+lw== |
      | 2133955c-137f-4422-9290-9a364b1a40a0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-setup.exe           | exe      | windows  | x86_64 | BQfSyTfYWnHrl7LywK/fcioco+6IM4y1ermCGf5MjV1HT9VZ5ZtWRlQUM0UrPEXZct/gFYOf/THLk7mTvLUw1A== |
      | 8700e88b-17b9-45af-91a7-6f7d1de7038e | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-setup.nsis.zip      | zip      | windows  | x86_64 | 1lbG9323YV/MyW9t+MbouA1mvWaJQG+Skd3hCFpU44AfTS+jmQGiAyOqbdGa9zyDkEzeeoJeoqR+j3cq06uqBw== |
      | ba8dd592-2c3e-46bf-afdc-dabc2fed9d8e | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-setup.nsis.zip.sig  | sig      | windows  | x86_64 | gBbZS6U0bu6lDtfT0ntoATXijot9PwCTj38rSD0Np7Vs6Jh73oL7caa9Td4MFHq/wt1t70gLPPaHoNvOWEN+2w== |
      | eaa67d65-f596-427a-8f64-80a7125ae299 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.msi                 | msi      | windows  | x86_64 | OE7wQq5K4TNsQ2nyZCuJhpOSS45t5/G0S3IbPKhOhVWYUJtwu4a4wwTHr04f6JTas8jiklJPdLS3wuXZ749fEw== |
      | 6fdd494d-3fec-40a5-80e3-c3e9f71c7aa2 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.msi.zip             | zip      | windows  | x86_64 | 2ZnUI98WjokH4p/xu2U9T7Rg0J6byDF33lABy+8G+MkEBt3iKOuu7m25x/o95qYAQQRoG+I6Gi/lpl49xobVGA== |
      | c185d92b-1232-4bdd-9906-fa4d99e259c7 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp.msi.zip.sig         | sig      | windows  | x86_64 | DbSIbY2X0YRCySCC+xQeeber/9A45KZxHSyjNh4FSfQRkbK/jTCZ+MpIZ7geWu4Jx0FVq+7R9qj8Gtiz3TaEYg== |
      # 1.2.0-beta.1
      | 05f8a823-b80b-4453-a524-82332fc50792 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.AppImage            | appimage | linux    | x86_64 | Zd9e9c4l6Z1pHJPjFzYSWKLmzaQG1d/80hWMM5QbcnBBdNzObcJFGbmXJzAzrNRI1F9K6npGWlCFLZikvFm4rA== |
      | 62577251-fbc4-4bb5-bcd8-cf4bac39faaf | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.AppImage.tar.gz     | gz       | linux    | x86_64 | yfz/TKguPCzKru2jnYHqTk40g7sVBlPD00bHQK60iQ2ICG0tsfKq7j0Nc6gouyrtbwoiCUmZQE+xyEmKcyf/Vg== |
      | 623efc8c-c2c9-46a1-9d1d-ff24e34a3359 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.AppImage.tar.gz.sig | sig      | linux    | x86_64 | +X5qPRP3+DGO2JcTuakCVyTdCeK9xRrdMHfiqBFRMSiRKOImlhRN8ja5mK9FDtAqGlS0F9MnK2rITLzJh+uYLQ== |
      | 1eff1d91-02ff-44ec-8b44-1a11c10461ab | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.app                 | app      | darwin   | x86_64 | IFd4DUPeV53K7Ts6XvpT4GrnoZW25w1nYRXsyNEGo0n9yAbx4cs2NTrliHXz+GbPN5OaEadlCAul33WvvthJvA== |
      | 4502501f-8371-4aa8-acac-fff32c204a41 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.app.tar.gz          | gz       | darwin   | x86_64 | Dp/hr/+5PfyRzvYgm9CyFVixGeS662piAsKIeO2b/nHrS/XgPExt7l4mqkH1UWpDokC00eY2LbQjaf4c5bWi1w== |
      | 260b1b8d-bf7e-4738-bad0-5316373da8f5 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.app.tar.gz.sig      | sig      | darwin   | x86_64 | pwaEooOf8pKsr3VScsXUWjPB202reCD47KbOE0ZG2njOANH7wXifW4CMh6PRISsa08WkO41IGrhISX2C7kVwwQ== |
      | d5405732-577f-42eb-bd53-3bbc524072f0 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp-setup.exe           | exe      | windows  | x86_64 | HmRBSDpEPZJQThHKOVViieS5xhx8HN9B2xieSp/8CV7FbOVsC62l5KaM27wrG6DFYyCCVUboNaYncB2a7vvOYA== |
      | 2554c09a-8c0d-42e9-8108-fb5cfe7e4fab | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp-setup.nsis.zip      | zip      | windows  | x86_64 | ZItzHtqyMtpKPYTtP5oYKXSaqLazZnOWVMsVxb3zadJLs/OsBFrJ4iM/+RQm5N7RReHLg6uonI6ACQr80PRSTQ== |
      | 419ba987-9184-4baf-82bf-8ca9baa4e267 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp-setup.nsis.zip.sig  | sig      | windows  | x86_64 | uAAQVTGXau6Y6WNUIHBEzahPFn34E6poG78Ip9Bc9urgLuTzZgyQAaohS6nU4wuQdftUTwZbVxpYpXlAh/fDbg== |
      | becabe1f-4b3f-4a83-9ab4-27fdb1ba07fe | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.msi                 | msi      | windows  | x86_64 | 167ASeXh6NLamALrvdbIEpuB2PJqLpkrBHpvTy0L7FSvDTQZzGwY7b0zBgFlHyHlSnzJw9y2dC4xQgYAK5EiwA== |
      | 479cb7f4-5780-402e-8e00-4a9ba4eecfe4 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.msi.zip             | zip      | windows  | x86_64 | nWkIH+FRn34NTIFZj6F12kOjmoM610thmTuf6lm/i4Hbcx06SYtAotrBaCyTxaqo4bdaBNbyqYLr6i84LZ3vmA== |
      | d2801d8a-5ce8-4c48-89ee-7177d7dcc84c | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp.msi.zip.sig         | sig      | windows  | x86_64 | uUsbx9f9ZGlN/45rBK3ZRy7/QNJNdsyG5f18dIt1FO0caAPr5cBxBIuUAbmIC7FnrECrDLcaL18GQ8MeB86WOA== |
      # 1.0.0-beta.1
      | 699a9b1e-6d57-428a-b039-cb387de7d6ff | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp-setup.exe           | exe      | windows  | i686   | dQj9GEoEqv0jxagPuks0zPCs3RIXi0fBvxsXUEkyeNwt372dRtjyJxHNAzEys9vsWCAI+FcH3erTmzVwtoQkgA== |
      | f5e7fa7d-7684-4cab-ade6-bdea58fa2d4c | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp-setup.nsis.zip      | zip      | windows  | i686   | R5vsdOmH+jxZ6Cer0iu2XIbJDed7yWW12nGLnmd+1/m8P/6tVgJKgAuJlbz+VUef3YGWbo0Vq5yDhCcod/R4nQ== |
      | f36df79d-5952-4d7d-ae13-87198e1cd0f0 | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp-setup.nsis.zip.sig  | sig      | windows  | i686   | nr20BEyN5xnWX3I+OxDX85GhGoABpvJGevnmo95nBdHdxFxKCQMLRwQaVqCh++RRRAWv22Hq1VZcxpwumOwuLw== |
      | 375d8a5a-e839-4bc1-a168-e376baf27c78 | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp.msi                 | msi      | windows  | i686   | foTILz/82kERvo9wdYprCKw/zCq4tA409RSnFAhMbSXbn6Co9MBmSIVjVFaVIP/cy74oXDUAuRHscQVwEUH1rA== |
      | 23b0c365-1941-4036-b60b-c3f669f1da35 | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp.msi.zip             | zip      | windows  | i686   | rIZq0l+CqaSuv52Z2VjiXXnbpURrIXoZuZKvTr9TlCb9cikY2egwBWCLBekurbFiNfwzzeWrjZlefb/t14pAnQ== |
      | ecdb59f6-00c1-4fec-80bd-7fc176f9d1a0 | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp.msi.zip.sig         | sig      | windows  | i686   | qJ6ij921jgD6yJ3UknE5IFAiSfFPTcUZPkqGj+WwfedTKPz7d7NmiUZRxPoajz/GKLimBoXdEm0a57L+yFEejw== |
      # 1.0.1-beta.1
      | 05b82ab6-ad64-46d4-9885-97a23347eb1c | 29f74047-265f-452c-9d64-779621682857 | myapp-setup.exe           | exe      | windows  | i686   | w3tDl0PCRIBM8t07D8fWpl102zpxiKKYJ8E6oCLBxiXYBB3Zvb52osFgrw6H8nPrqNu3Ax0NV8VKtBmmxxUN3A== |
      | 2d719642-aec6-4e76-86af-5de76b9c2491 | 29f74047-265f-452c-9d64-779621682857 | myapp-setup.nsis.zip      | zip      | windows  | i686   | JMPKKgalgzGHfQ7TBCRTR4NU6rqWZeQpLDWrkjswTc/mztdShLLPMG0I9tdNFi0qlCtMXAHXYPUR/YQSQFLEOA== |
      | cefb4032-6e1b-4411-8e85-f5d7d8a269a2 | 29f74047-265f-452c-9d64-779621682857 | myapp-setup.nsis.zip.sig  | sig      | windows  | i686   | dA4En1FgSfi+6O8O+DY5bCchQkVxRGR8w+4pKfGjpug6+/4wwrZgmlhOfs364eKVtf7UcWsZ9vopF0E6HV28UA== |
      | 1adda3a2-021d-4d76-b715-6907ce7d78c2 | 29f74047-265f-452c-9d64-779621682857 | myapp.msi                 | msi      | windows  | i686   | G0ocYvc2INVNpBcaoDEaAwQhAxX9/xxNv1g44NICAnMU+Z8V6ohUGtoX2Q8adDOo7JE8/picj+i1gwWb5Em1Fw== |
      | 7cd42443-f93e-4a28-8f7f-57a0aa8b8ac2 | 29f74047-265f-452c-9d64-779621682857 | myapp.msi.zip             | zip      | windows  | i686   | HdjLw2BS/1lBKUtoamPrTQWhdHAMsKhz96Z6OHoQPh8h/9CfFH+JtA+RbPNVSpEidBD9tmYM0SOaHmVHmr/Bwg== |
      | 2986a294-fc70-4a99-805e-e91b90b4ec2b | 29f74047-265f-452c-9d64-779621682857 | myapp.msi.zip.sig         | sig      | windows  | i686   | CW5imayiWMU50dYJIW1CMDxMW0qr01YUGd97r4IOs2WZlpcl1OIyeYvKgDNAJXkBBSbi9QPG21I3OxJxecsoBw== |
      # 2.0.0-beta.1
      | 16b9a3fa-6b12-4d86-b81e-be2757392bae | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp-setup.exe           | exe      | windows  | i686   | 1/ZheqnqL3OJbQcUa+zmFCENiXqhW1oqrUP2sREyExryaDRcy14lC6nSHg4gt/TfbHkE1ANnsEFizRdno+uZZg== |
      | 8dbd9795-2b57-436a-863e-26a3e6689f38 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp-setup.nsis.zip      | zip      | windows  | i686   | 6vfPB8J8IW1AlSkc7e4XOiLFIPelzQYQyN+nrXMNsBr+Tb7IWjNKRZxDH/rlOhXjAqkY24SxD56suQGY+ELkYA== |
      | e1a9d063-cd8d-4655-95e5-647c961852eb | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp-setup.nsis.zip.sig  | sig      | windows  | i686   | Rpvx4kMZlfBr1lM7GwA1tJA7qeRGfNACOIYXwyxqTH6RkqIvcNcB8dl3ZcdEqdF46l1oFDiWYcI5xYE35/NSlA== |
      | 61987e0a-1848-4a04-9b2a-86ff6a7f464b | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp.msi                 | msi      | windows  | i686   | 3vw5nDxg8qAZ4yPtPvBb0BJf5I+Df7zveGPDWEhOFAfeSfPhUuxbwePy/inD16AQM/K2ovHPpBMsZ9nmpI/r9A== |
      | 0220fd5b-e35f-452f-980f-6a7447c71163 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp.msi.zip             | zip      | windows  | i686   | DM6TUNOgzD11U2bgEEuNfxKOssq5ElscX/AIgd5Oczl4ufIoYViVdT0U/hin5jx7pySy3WW7J5tlS/lt5U5xPg== |
      | dd61752e-187e-4346-a7df-fda80adb7131 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp.msi.zip.sig         | sig      | windows  | i686   | /oBea3DwxhueGOhoKQ9JxTBHamr9cp85WyJI5p50FeRqq9zELjroza7h5/c33CgZGnx1klSo4omAqWgdupx+8g== |
    And I send the following raw headers:
      """
      User-Agent: tauri-updater
      Accept: application/octet-stream
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=linux&arch=x86_64&version=1.0.0"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  Scenario: Endpoint should not return an upgrade when an upgrade is not available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=linux&arch=x86_64&version=1.1.0"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should not return an upgrade when a version does not exist
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=linux&arch=x86_64&version=3.0.0"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return an upgrade when an upgrade is available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=linux&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/6ce09e8b-26e7-4524-a10e-a410fc6580b0/myapp.AppImage.tar.gz",
        "signature": "bTm5t7bH2G9o3NAYgd4MGx7/nwnKCd+q4cdelm20tzcEpRepzto0KNmVl7z+AgiOOW6Cxkqyp0/zR2IntMnN7A==",
        "version": "1.1.0"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should prefer NSIS over MSI for windows
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app2?platform=windows&arch=i686&version=1.0.0-beta.1"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/8dbd9795-2b57-436a-863e-26a3e6689f38/myapp-setup.nsis.zip",
        "signature": "6vfPB8J8IW1AlSkc7e4XOiLFIPelzQYQyN+nrXMNsBr+Tb7IWjNKRZxDH/rlOhXjAqkY24SxD56suQGY+ELkYA==",
        "version": "2.0.0-beta.1"
      }
      """

  Scenario: Endpoint should include release notes when available
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "notes": "bar" }
      """

  Scenario: Endpoint should include publish date when available
    Given the second "release" has the following attributes:
      """
      { "createdAt": "2023-08-15T00:00:00.000Z" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "pub_date": "2023-08-15T00:00:00.000Z" }
      """

  Scenario: Endpoint should constrain to a semver constraint
    Given the second "release" has the following attributes:
      """
      { "createdAt": "2023-08-15T00:00:00.000Z" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app2?platform=windows&arch=i686&version=1.0.0-beta.1&constraint=1.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/2d719642-aec6-4e76-86af-5de76b9c2491/myapp-setup.nsis.zip",
        "signature": "JMPKKgalgzGHfQ7TBCRTR4NU6rqWZeQpLDWrkjswTc/mztdShLLPMG0I9tdNFi0qlCtMXAHXYPUR/YQSQFLEOA==",
        "version": "1.0.1-beta.1"
      }
      """

  Scenario: Endpoint should upgrade from stable to beta
    Given the second "release" has the following attributes:
      """
      { "createdAt": "2023-08-15T00:00:00.000Z" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=linux&arch=x86_64&version=1.1.0&channel=beta"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/62577251-fbc4-4bb5-bcd8-cf4bac39faaf/myapp.AppImage.tar.gz",
        "signature": "yfz/TKguPCzKru2jnYHqTk40g7sVBlPD00bHQK60iQ2ICG0tsfKq7j0Nc6gouyrtbwoiCUmZQE+xyEmKcyf/Vg==",
        "version": "1.2.0-beta.1"
      }
      """

  Scenario: Endpoint should return error for non-Tauri packages
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/pkg1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "404"

  Scenario: Endpoint should return error for missing platform
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?arch=x86_64&version=1.0.0"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "parameter": "platform"
        }
      }
      """

  Scenario: Endpoint should return error for missing arch
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&version=1.0.0"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "parameter": "arch"
        }
      }
      """

  Scenario: Endpoint should return error for missing version
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is missing",
        "source": {
          "parameter": "version"
        }
      }
      """

  Scenario: Product retrieves an upgrade when an upgrade is available
    Given I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=windows&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/8700e88b-17b9-45af-91a7-6f7d1de7038e/myapp-setup.nsis.zip",
        "signature": "1lbG9323YV/MyW9t+MbouA1mvWaJQG+Skd3hCFpU44AfTS+jmQGiAyOqbdGa9zyDkEzeeoJeoqR+j3cq06uqBw==",
        "version": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade when an upgrade is available
    Given the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/77aaaf13-cfc3-4339-8350-163efcaf8814/myapp.app.tar.gz",
        "signature": "qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw==",
        "version": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a release that has entitlement constraints (no entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the first "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade that has entitlement constraints (no entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the second "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade that has entitlement constraints (has entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the second "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "license" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/77aaaf13-cfc3-4339-8350-163efcaf8814/myapp.app.tar.gz",
        "signature": "qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw==",
        "version": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade when an upgrade is available (license owner)
    Given the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/77aaaf13-cfc3-4339-8350-163efcaf8814/myapp.app.tar.gz",
        "signature": "qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw==",
        "version": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade when an upgrade is available (license user)
    Given the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/77aaaf13-cfc3-4339-8350-163efcaf8814/myapp.app.tar.gz",
        "signature": "qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw==",
        "version": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an upgrade for a closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an upgrade for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/tauri/app1?platform=darwin&arch=x86_64&version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/77aaaf13-cfc3-4339-8350-163efcaf8814/myapp.app.tar.gz",
        "signature": "qjuxG7/3e44SUMRWSc8h3mOMk11L8lMSpKmEujgYmSjc+PnRY/Jedbw74a0+AMWkGSBCXvOISWK3bfylbNkaxw==",
        "version": "1.1.0"
      }
      """
