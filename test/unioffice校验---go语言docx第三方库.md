 go中除了unioffice就没有很好的库去处理office文档了，基本上unioffice是唯一选择 不过unioffice使用需要许可，但他又开源，所以分析一下校验逻辑 源码经过混淆，但是还是可以直接看到逻辑

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765685793289-5beb4c01-eb22-432c-9cad-d5730321843f.png)

<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">跳过来看到这个逻辑，很明显</font>`<font style="color:rgb(192, 52, 29);background-color:rgba(0, 0, 0, 0.04);">_ggg</font>`<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">用来处理许可</font>

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765686112120-dc7696cd-c066-4031-92cd-b5f15d2d9038.png)

<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">这边能看到会调用一些常量</font>`<font style="color:rgb(192, 52, 29);background-color:rgba(0, 0, 0, 0.04);">_fa</font>`<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">,</font>`<font style="color:rgb(192, 52, 29);background-color:rgba(0, 0, 0, 0.04);">_gd</font>`<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">,</font>`<font style="color:rgb(192, 52, 29);background-color:rgba(0, 0, 0, 0.04);">_ecg</font>`<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">等</font>

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765686129891-b02f6aec-00bc-4352-b065-98cbe7b203d6.png)

<font style="color:rgb(35, 38, 59);background-color:rgba(255, 255, 255, 0.9);">常量字符串都经过unicode编码</font>

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765686147654-360bf2ee-8a78-40f8-9cac-f0050d59590e.png)

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765686158260-c3c4dde0-c35f-498c-9961-1012dd453656.png)

 根据内容，大致可以知道许可信息的结构，因此_efa就是为了获取中间的许可信息，下一个_bef则是对许可信息进行处理

```cpp
-----BEGIN UNIDOC LICENSE KEY-----
许可信息
-----END UNIDOC LICENSE KEY-----
```

 _bef函数上来就先对许可信息进行判断，大致就是判断里面是不是包含了特定的结构，如果要构造一个许可，那么只需要满足这3个中的任意一个就行了，第一个实际上是\n+\n

![](https://cdn.nlark.com/yuque/0/2025/png/34851136/1765686201647-244831d8-24aa-4381-a571-067304bc2f09.png)

因此可以得到许可结构

```cpp
-----BEGIN UNIDOC LICENSE KEY-----
part1
+
part2
-----END UNIDOC LICENSE KEY-----
```

 这里很明显就是分别对两部分进行解码，_bfed是定义的base64的别名，因此可以知道part1和part2是base64编码的 后面加载了公钥，所以这个函数的第一个参数是公钥，那么即是说，只需要生成一对密钥，然后将公钥替换，就可以使用自己的私钥生成许可了 后面就比较简单，对许可信息进行签名校验，从而知道了part1是明文信息，part2是签名信息 最后就只需要确定正确的许可信息即可，下面是对应的结构体 自此我们可以根据结构体映射的json创建一个属于我们自己的许可信息并使用自己的私钥签名 最终在验证许可时要求LicenseId和CustomerId的长度不小于10，创建时间是时间戳，过期时间为0则是永久授权，另外客户名称和一开始传入的参数要相同 最终授权信息长这样

```cpp
-----BEGIN UNIDOC LICENSE KEY-----
base64({"LicenseId":"1234567890",
       "Customer":"1234567890",
       ......})
+
base64(rsa_sign({"LicenseId":"1234567890",
       "Customer":"1234567890",
       ......}))
-----END UNIDOC LICENSE KEY-----
```

