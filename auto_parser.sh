#!/bin/bash
set -euo pipefail
IFS=$' \n\t'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

commits=(
    "9524b8c3702e204d9f942090acb39a3549c80ca8"
    "d17aa98262480c17051c66353ac4ec300ab8033c"
    "386e7f82086454a2fc18bf4ff667560a5dd3c981"
    "05273fa8d2a6a0cd6730cd4b004dbbc8adf9aac1"
    "2457f5ff2293f69e6de5cc7d608dd210f6b8e27a"
    "7ae537657396fda92f497ce1b24a68f2d9f1e615"
    "d40514391941e0d8bea0ade89cab55f6ee2001e7"
    "7af3a981b52390adee19a7af3ff206aecf58af94"
    "1b3e6a483172ef8976d5805811d73b14c3b3f0d2"
    "a2c8fe0370156cb73ca64d84a86ef63359a69567"
    "ac672fc3ffcb20e07cd6b9332cc8115c3a99579d"
    "3fa4962a883d8edfa0821f30e25aaafd859cba33"
    "0533022d631e0fabea4de74550fc51faefbcf8cd"
    "094c84ed6d332af7c7e24affb81ff76fddaa4158"
    "071b7b2a0308d3b65f2deafc0a004a340e6ead86"
    "1af45689f9bdac7267400a8c9d77c23676b33935"
    "97cc95510159892288fc8cc92c6480d8f0b57799"
    "c4cdebacfeeecac259273f3ff62c0139131ba490"
    "e8c1bfc2e560b6181efce69df9881cd44c44917f"
    "23efd9d2781c2ac22594a83afa75182d276b1571"
    "cb8c9d5bcf6406bc89e1542ba94b778f15a5a348"
    "97292da96048b036cbe36b3ea66503ac568a73e7"
    "aa4d78431f1acaff1aca8ec1c2b2dd36834d68dd"
    "8735fcdb7d296563c475bec5b8d7a3c8945ad3ca"
    "bffbf08f26656c2c073da2a989f3abc38fdbb444"
    "df1e7d0067bb39913eb681ccc920649884fb1938"
    "c2053dd076d28f576385216192bac76a266fe77b"
    "7c0ab8b9741c0f63fc22be49a1026da52f4375a0"
    "c6a53c3172b6da826e5f7f2f59d744308e9567bf"
    "d95102d650673165785a05d1cd07a75a3f8763cb"
    "6f960f23e538123d061dc8ff5b0e70433ccd6181"
    "59f9ef9feebb19337b8a153e6cac0371ca706268"
    "391635784051eb343fea9a2dba3058d58f2df59c"
    "1859bbbf9122b258f27526c4dc7d857028264997"
    "089f51a63c92c1d72d0d6f6f59973b652f2ff263"
    "e2e0280108cd0cfa4aaa7a875b2c81f17b1352e1"
    "c7a389f2b2667b7bfc264a0be519b5c85e0a3b94"
    "dfa4e5857fe9d8f113cf50d4c7fda094f0f30b74"
    "3518a1d4cdd5b366d91726b654fcabf66da27ec7"
    "cb68e01e22fb20cb0e23090654a4e7285fb8d933"
    "27ee15e86e5dc07c05a7a721453cff29388feb2d"
    "cda97a725347cdadd43af812749732b9d1ee6429"
    "540bf9fa6d0d86297c9d575640798b718767bd9f"
    "f064d716c3972f38249533602b41f8a68dcffc27"
    "6c73c0da530649d0d629359e13d0373b72568f41"
    "aa678b80985c5dcb92cef15e19bd963c47a647db"
    "a66d883a18c5eefc475c3b61c0842a87b4ce250f"
    "43652746f2929aeb53ec1e575c3691050755a0b5"
    "ced34bab1a7d5bfdc2bf67d67ff447e9d8b7a9d3"
    "76c7df9630f0cd4b8a4ec0e4f56f42df92db4730"
    "f3fbb7c67d21c01a58653c7ef9ae0e80dbb4becd"
    "20f022de72b40f55b465cbb97982dead190fcd16"
    "2cbd377e1f8d01c1e4a472f6ca5d770af63dbea4"
    "726f3b1d84067c520095b83e7d64a7abb7fca879"
    "63ab92d7971e4931e98f014f2c5385d2242fa780"
    "72c1f207152c7e30d3af70918bca6456c7315123"
    "c2e0143bfe35b539bdbec9971e83fa9f9ab78034"
    "40b99a5f892c210befa530592639cb77fa16bbe9"
    "02d5f422eab2f2b7ba8f61dcdef5bea96950061a"
    "4df238bda065b7cb4f995e42bc0d9b10f9116927"
    "9a65d011f6b289dd6e7acb18a4b86c51d4d388ee"
    "c480d7fe6db36725766f08700d598094c5b10170"
    "321383db22b19e302aafe59194f0b6539257d90f"
    "e90db3f5cc612bd8cec39d234f5408aff1425409"
    "f1cb461c1fb23b68ae34ada2de6bad3bfa6ceeca"
    "4e5bf595794657c80dc71aab5b3884b327110cae"
    "65d3e1161b0544f50d94dbbecb6bcf135535e112"
    "345ceeb98f01f51e52944548ef071b1d4d595e6d"
    "d44a415bf019393b85a33aa31244f52d43f55080"
    "3afc3e4a71d0be405ced38c88dcd6bad04c3043f"
    "cb786f0d4062ec0b75fc1c3ab5f4d4fc1955bbf7"
    "3d1fda737bc36e80a670f856fd85f6b884872b73"
    "54556053420a8ca37dbd53fbdb6f9251a2db63d9"
    "520eb57d7642a5fca3df319e5b5d1c7c9018087c"
    "8bb5e8b2b49017bfded2239f9ca87387e33c2cb5"
    "a5acec329e2ca61044f1e1d96858624f2c4a46ac"
    "faae819f5d8a662ec2df88205ab6d9b1871f1dd1"
    "be2de105f5bf55132f19c6a219a8297d4f3cfc64"
    "c7612d178c5b954d4846cd27a65a7fa15fd1ba65"
    "0dbcf3a3e897522369f377221c286afb16436396"
    "309354c70ee994a1e8f261d7bc24e7473e601d02"
    "d81659d03947ac4533099089c5f442437e1d6887"
    "d26fce399536ddf740cfdc30b11fa4963cc4c6a2"
    "6f9c278559789066aa831c1df25b0d866103d02d"
    "5eb4c6386709259a9280c5aad6e0488f381144c5"
    "35d2fa744aae5782dcced573aa08ee9ff62c8e36"
    "de51b2162450a46a48d2bd97501066d3b0d4ee87"
    "e8186f1c0f194ce3f63bed9a564002b80c0859c9"
    "c3985f05e84b6415b8b117870a9a123d4c2832a0"
    "4011821c946e8db032be86266dd9364ccb204118"
    "2903afb78f77ed94c0515a6e58e27c23a13f2671"
    "6fc17ad37bb4eb07f595d975937cccd20aa8edcc"
    "0f4e1b9ac66b8ffa0083a5a2516e4710393bb0da"
    "a89b399faa275c28d0ffe9759d492636f67d6da0"
    "c53f802778c1951e0804507eec995bca37f1b09b"
    "044c754ea53f5b81f451451df53aea366f6f700a"
    "085f717529008c31b147f76ea7eeaf06ca8801bd"
    "3963625b6ef6f4d4f16959466c077593a1f908db"
    "49f9d43afefd446287b1b2475d7127d405b7a873"
    "1d332342db6d5bd4e1552d8d46720bf1b948c26b"
    "062fd4c217cc7302f56acf043d6214a9db46ee2f"
    "17030ced75059ec21f6fb1945a751c3ebef29a32"
    "a4148c0f12fe5a93d2c9a40f24d4813bcfef4ff8"
    "ac701637b42d2d6bb5fe9b258f3f54959b6a505e"
    "e6acce649b348cc497b999100a170866a90c87b8"
    "0851a895819e0a5a1a79dcbd596d4c93d4d47a76"
    "ab22ab4a37110e989e2060fb088798e783dfcec7"
    "dd29ecb3337fb24931a386fe0cfbcecbe351f34b"
    "e2043987543d6b1e94afc22d145d70ddaf814898"
    "e7d65cbc6e50d70753f7228c46cbff0cffde7eba"
    "1f12dc8e8862da8546fd9d984abdc7f69dd95f11"
    "0903b1ac8c7b64bb571d02cdd69fa671cc1c18c1"
    "6f6edb8fab5550a879a09af9530dd10d5c8d7f6d"
    "4974b7c120102b49548197e58c7a58181ba52170"
    "ef89e75d0eb232e98ca7a7ef278b8681c7f4fe50"
    "791b109d6f5a4e35c1fdd158d082e86225306db3"
    "61db8349041cceceb4ad3233e69613705bd0a128"
    "67b316a954b161cac27e16b6455837881919dd94"
    "be06dee04ce46de2da222fc9b2be4fc3b68b816d"
    "8ab35eefc4ff5db3f2f0a62f6f0272eae9be0585"
    "d7ac9727bb5046118915cbb26b2dac1b7b27c9d4"
    "21ae9838e04233bbf9930d368d935fd1f9b68c34"
    "dad67cae5455f346f122ab26ec50ac4e029cacf4"
    "273a24f22676b73a648fd2a5467e385ec41e84e2"
    "016a5d0438e551d4630819683dd6dc4fccb0cb51"
    "0109229928d8603ebedc2364943538f788635370"
    "8a84d82d5341ff6572e7c77f5779e2583ed45c25"
    "aaeef295bb07b281fe0554aa6e97f24596d073aa"
    "491887d44132b8103ed0d753f95ecd43d600adba"
    "022d2d8beb6297016ed26b0090c6a4a4ac404437"
    "8f26397928b33a16558dafc2716a72b6e6900bf4"
    "4b8d9e58c58b8952e86e7e5f90a0a8e0480e1de1"
    "ac6accef092ea5a983a4a8ee35282246fc3c6fc5"
    "f694bb45d79dcc093bc6332eabb3af063bc6b088"
    "af8957bc4ce78613fe03cb1abc6c961dd67ff344"
    "c66c9dabc7453febc0e01fcc974baf06fd96c38d"
    "495d5e4329326b27158a25b44c37986923d0bb6b"
    "9e85358777ea4bd345f832d08b19915a72cc128b"
    "6aa3f8bc29cb1ed3a1b165cbf526079a751c8c71"
    "20477a69ea123a7800ebf94bfd2225eb9ae90e8f"
    "c8650aef0aefb06ff416912e4ae5f42eaa53ef63"
    "82e08a3364195b515a005180c2bdc08e78aac208"
    "beab2df1227f9b7e556aa5716d94feb3a3e2088e"
    "ea619b39b2f2a3c1fb5ad28ebd4a269b2f822111"
    "dd62ca7ba9b49e799a8bea896cff1b209f813b7e"
)

run_script() {
    commit_name="$(git show --no-patch '--format=%at_%H' HEAD)"
    echo "$commit_name"

    # Don't run if no .go files were changed.
    if git diff HEAD HEAD~ --name-only | grep -P '.go$' > /dev/null; then
        # The go.mod file was added in d77176912bccf1dc0ad93366df55f00fee23b498
        if [ ! -f go.mod ]; then
            # Use the modern go because the old one doesn't produce a go.mod that can be read without running go mod tidy afterwards.
            # Running go mod tidy afterwards doesn't work because of some strange error.
            # go: github.com/mvdan/xurls@v0.0.0-20181021210231-e52e821cbfe8: go.mod has post-v0 module path "mvdan.cc/xurls/v2" at revision e52e821cbfe8
            go mod init
        else
            # 5efd3630bc21d4b0ba6ff492d16d4c7e2814dd1f updates to xorm v0.7.4
            # Before `go mod tidy` didn't work.
            sed -i 's#github.com/go-xorm/xorm v0.7.3-0.20190620151208-f1b4f8368459#github.com/go-xorm/xorm v0.7.3#' go.mod

            # We need to download the old tools because at some point the new tools fail to work with the old repo. (somewhere at go1.12)
            go install "golang.org/dl/go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)@latest"
            "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" download
            # ed1d95c55dfa91d1c9a486bfb8e00375d4038e29 repairs something that makes loading fail otherwise, solution: go mod tidy
            "go$(cat go.mod | grep -P '^go ' | cut -d ' ' -f2)" mod tidy
        fi

        /home/chris/go_observer_pattern_visualizer/parser/parser \
            /home/chris/forgejo/ \
            forgejo.org/services/notify,code.gitea.io/gitea/services/notify,code.gitea.io/git/services/notify,code.gitea.io/gitea/modules/notification/base,code.gitea.io/git/modules/notification/base \
            RegisterNotifier \
            forgejo.org/services/notify.Notifier,code.gitea.io/gitea/services/notify.Notifier,code.gitea.io/git/services/notify.Notifier,code.gitea.io/gitea/modules/notification/base.Notifier,code.gitea.io/git/modules/notification/base.Notifier \
            > ../out/"$commit_name.json"
    else
        echo "skipping as this commit doesn't change any .go files"
    fi

    # Apparently the go dir can grow to absurd sizes; prevent that.
    if [ "$(du -bs /root/go | cut -f1)" -ge "1346239233" ]; then
            rm -vr /root/go
    fi

    git restore .
    git clean -f
}

# while true; do
#     run_script
#     git checkout HEAD~
# done

for commit in "${commits[@]}"; do
    git checkout "$commit"
    run_script
done

