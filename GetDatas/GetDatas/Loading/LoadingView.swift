import SwiftUI

struct LoadingView: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            if isActive {
                CarouselView()
            } else {
                VStack {
                    Spacer()
                    Text("raem")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.deepNavy)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // 2초 후에 CarouselView로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isActive = true
                    }
                }
            }
        }
        .background(Color.white) // 배경색을 흰색으로 설정
        .edgesIgnoringSafeArea(.all) // 전체 화면에 흰색이 적용되도록 설정
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
