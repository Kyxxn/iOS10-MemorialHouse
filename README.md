## 🏠 기록소 - Memorial House

<img width="77" alt="iOS 16.0" src="https://img.shields.io/badge/iOS-16.0+-silver"> <img width="83" alt="Xcode 16.1" src="https://img.shields.io/badge/Xcode-16.1-blue"> <img width="77" alt="Swift 6.0" src="https://img.shields.io/badge/Swift-6.0+-orange">

<div align="center">
  <img src="https://github.com/user-attachments/assets/aab0f5d8-01b8-4d03-ab3f-9970bcca6ec3" width=900>

  #### 사랑하는 이들과의 소중한 추억을 기록소에서 책으로 엮고 출판해보세요.<br>
  #### 따뜻한 일상부터 특별한 순간까지 추억을 출판하는 곳, **기록소 🏠**

</div>

<br>

## 🍎 기록소 주요 기능

<div align="center">
  <img width="852" alt="image" src="https://github.com/user-attachments/assets/8f9c8f86-7707-4699-bba3-bcf08faf3b82" />
</div>

##

### 🧱 아키텍처

> ### Clean Architecture + MVVM

<div align="center">

<img width="980" alt="스크린샷 2024-11-28 오후 11 04 05" src="https://github.com/user-attachments/assets/87b86b8b-2b5f-487e-b648-4eeb80610a36">

</div>

- View와 비즈니스 로직 분리를 위해 **MVVM 도입**
  
- 추후 서버 도입 가능성을 고려해 **Repository Pattern을 적용하기 위한 Data Layer 도입**
  
- ViewModel의 복잡도가 증가할 것을 예상하여 **Domain Layer를 두어 Use Case에서 처리**

- 테스트 가능한 구조를 만들기 위해 **Domain Layer에 Repository Interface 구현**

##

### 🛠️ 기술 스택

### Combine
- MVVM 패턴에서 View와 ViewModel의 바인딩을 위해 Combine을 활용했습니다.
- Combine은 First Party 라이브러리라는 점에서 안정성과 지원이 뛰어나며, RxSwift에 비해 성능적인 이점이 있어 RxSwift 대신 Combine을 도입했습니다.

### Swift Concurrency

- 비동기 프로그래밍을 위해 Swift Concurrency(async/await)를 활용하였습니다.
- 기존의 콜백 기반 비동기 프로그래밍은 코드의 깊이가 증가해 가독성을 해치고, completion 호출을 누락하는 등 휴먼 에러가 발생할 가능성이 있었습니다.
- Swift Concurrency을 도입하여 위 단점을 보완하여 코드 가독성과 안정성을 높이고자 했습니다.

### CoreData + FileManager

- Local DB로 Core Data와 FileManager를 함께 활용했습니다.
- Core Data는 책과 페이지 간의 관계를 유지하기 위해 사용하며, 각 페이지는 멀티미디어 데이터를 포함할 수 있습니다.
- 멀티미디어를 Core Data에 직접 저장하면, 책을 펼칠 때 모든 데이터를 한꺼번에 불러와 성능 저하가 발생할 수 있습니다. 이를 방지하기 위해 멀티미디어는 FileManager를 통해 디바이스에 저장하고, Core Data에는 해당 멀티미디어의 URL만 문자열로 저장했습니다.
- 이러한 방식으로 페이지 로드 시 URL만 불러와 메모리 사용을 줄이고, 필요한 멀티미디어는 개별적으로 로드하여 효율성을 높였습니다.

##

### 🔥 우리 팀의 기술적 도전

### TextView에 멀티 미디어를 첨부하는 방법
TextView에 이미지, 비디오, 오디오 첨부하기 위해 다음과 같은 동작을 한다.
기본적으로 TextView에 NSAttachment를 넣고 싶다면 NSAttachment를 만들고 NSAttributedString으로 변환한 후에 TextView에 반영하면 된다.
1. 이미지, 혹은 Data를 통해 NSTextAttachment 만들어야 한다.
   <img width="637" alt="image" src="https://github.com/user-attachments/assets/2915a1e0-a9ba-41b4-82d2-e9eb46869170" />
2. NSAttributedString의 생성자 파라미터에 Attachment를 넣어준다.
   <img width="636" alt="image" src="https://github.com/user-attachments/assets/c556b0e9-839a-40cd-8af7-0ff650687baa" />
3. TextView가 갖고 있는 NSTextStorage에 추가해준다. (또는 TextView써도 됨)
   <img width="536" alt="image" src="https://github.com/user-attachments/assets/011d5cd2-b1f4-4573-9943-aefb1048b22f" />
4. TextKit 내부 동작에 의해 NSTextAttachment가 처리되고, TetxtView에 보여지게 된다.
   <img width="553" alt="image" src="https://github.com/user-attachments/assets/fa466496-6903-427c-af7f-13f0fb279416" />
이로써 프로젝트 MVP인 텍스트 뷰에 멀티 미디어를 업로드할 수 있었다.

##

### TextView Reload 최적화하기

### 문제상황

TextKit의 동작 방식에는 중요한 특징이 있다.
컨텐츠 내용이 변경될 때마다 전체 (보이는) 컨텐츠를 다시 그린다는 점이다.
그러면 위 사진과 같이 사진이나 동영상 같이 무거운 파일이 들어가있다면, 매번 글자가 적힐 때마다 CoreData로부터 다시 가져와서 그려야하는 문제가 발생한다.
또한, 동영상같은 것을 보고있었다면 동영상이 재생되다가 타자를 치면 처음부터 봐야하는 문제가 생긴다.
이것은 원래 의도했던 효과가 아니다.
그래서 이를 해결하고자 `NSTextAttachmentViewProvider`이 뷰를 제공하는 방식에 대해 개선하기로 하였다.

<img width="553" alt="image" src="https://github.com/user-attachments/assets/03bd9b58-4c43-4d76-8925-984bf8267e67" />

위 과정에서 보면 Change Text시 NSTextElement와 그와 관련된 NSTextLayoutFragment도 변하게 된다.
그리고 TextKit 내부에서는 CoreText와의 상호작용으로 Glyph 처리가 되고, TetxtView에 보여지게 된다.

### 아이디어

`TextStorage`에 담은 게 내부 동작에 의해서라고 표현했는데, `NSTextAttachment` 에는 다음과 같은 메소드가 있다.

``` swift
func viewProvider(
    for parentView: UIView?,
    location: any NSTextLocation,
    textContainer: NSTextContainer?
) -> NSTextAttachmentViewProvider? {
    ...
}
```

NSLayoutManager 단계에서 `NSTextAttachment` 가 화면에 표현될 텐데, 이때 위 메소드가 동작해서 `NSTextAttachmentViewProvider`를 반환한다.
이후 `NSTextAttachmentViewProvider`가 제공하는 view를 받아 이를 NSTextLayoutFragment로 만든다.
그래서 최종적으로 우리의 TextView에 보여진다.

**그러면, 위 문제를 해결하기 위해 위 메소드를 오버라이딩 하면 어떨까? 라는 생각을 했다.**

### 해결과정

서브클래싱한 `MediaAttachment` 클래스의 위 메소드를 override 해서 `NSTextAttachmentViewProvider`에 담긴 view를 기존의 TextView에 있던 뷰를 넣어주면 매번 다시 그릴 때마다 CoreData까지 안 가도 되지 않을까 ?

메모리에 올라와있는 view를 NSTextAttachmentViewProvider의 view로 넣어주면 어떨까 ?
위 생각을 기반으로 아래와 같이 개선했다.

우선 `MediaAttachment` 는 다음과 같이 멀티 미디어 View를 내부 프로퍼티로 들고 있다.

그리고 멀티 미디어 커스텀 뷰가 MediaAttachable를 채택하기 때문에 view가 될 수 있다.

``` swift
final class MediaAttachment: NSTextAttachment {
    private let view: (UIView & MediaAttachable) 
    ...
}
```

그리고, 위 메소드를 오버라이드한다.

``` swift
final class MediaAttachment: NSTextAttachment {
    private let view: (UIView & MediaAttachable) 
    
    ...
    
    override func viewProvider(
        for parentView: UIView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        let provider = MediaAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
        provider.tracksTextAttachmentViewBounds = true
        provider.view = view
        provider.type = mediaDescription.type
        
        return provider
    }
```
이러면 TextView의 콘텐츠 내용이 바뀌어서 Reload 될 때마다
MediaAttachmentViewProvider가 기존 메모리에 있던 view를 그대로 띄워주는 것이기 때문에 CoreData로부터 Fetch 하는 것에 대한 최적화를 할 수 있다.

즉, ViewProvider는 일종의 layout만을 잡아주는 역할을 수행하게 된다.

그리고 provider가 view를 갖게 되므로 참조가 발생하지 않나 ? 라는 생각이 들었었는데,

provider는 NSLayoutManager에서 뷰를 만들 때만 사용되고 이후에 사라지는 1회용이기 때문에 참조 문제도 없다.

이렇게 해서 TextView Reload 최적화하기를 성공했다 !

##

### 🧑‍🧑‍🧒‍🧒 집주인들

<div align="center">

  <img width="500" alt="image" src="https://github.com/user-attachments/assets/3607a9fb-dd84-4877-83ef-ac8e43e1bc27">

  〰️ 부산 워크샵 단체사진 〰️
  
  <br>

|<img src="https://avatars.githubusercontent.com/u/62226667?v=4" width=150>|<img src="https://avatars.githubusercontent.com/u/129862357?v=4" width=150>|<img src="https://avatars.githubusercontent.com/u/70050038?v=4" width=150>|<img src="https://avatars.githubusercontent.com/u/71179395?v=4" width=150>|
|:-:|:-:|:-:|:-:|
|🎨 김영현|🥇 박효준|👓 안윤철|😽 임정현|
|집주인 내 골드핸즈(= 금손) <br> 초고수 디자이너 <br> 영리아나 그란데 <br> 영카소, 영켈란젤로, 영흐|우리팀 리-더 <br> 발표 초-고수<br> 황금막내 <br> 열정보이🔥 <br> 문서화 장인|데(DevOps) 윤철<br>분위기 메이커<br>아이디어 뱅크 <br> 동의, 인정, 공감 장인 <br> 돌리기 장인 (조리돌림)<br>우리팀 MZ|살아있는 네이버 클로바 <br> 루루 집사 <br> 스티브잡스, 스티브워즈니악,<br>스티브 임정현 Let's Go|
|[@k2645](https://github.com/k2645)|[@kyxxn](https://github.com/kyxxn)|[@yuncheol-AHN](https://github.com/yuncheol-ahn)|[@iceHood](https://github.com/icehood)|

</div>

##

<div align="center">
  
|📓 문서|[Wiki](https://github.com/boostcampwm-2024/iOS10-MemorialHouse/wiki)|[팀 노션](https://kyxxn.notion.site/iOS10-12c9adb32626806c900ad008c85e7dcc?pvs=4)|[팀 기술 블로그](https://memorial-house.tistory.com/)|[회의록](https://kyxxn.notion.site/eb52137ca8374353adbd7fb6926e99e8?pvs=4)|[기획/디자인](https://www.figma.com/design/zgxogGGouOUsshAJkPeT86/MemorialHouse?node-id=0-1&node-type=canvas&t=b4rxjLDdHgzyH6p3-0)|
|:-:|:-:|:-:|:-:|:-:|:-:|

</div>
