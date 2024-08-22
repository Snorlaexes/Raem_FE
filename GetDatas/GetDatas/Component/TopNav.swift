import SwiftUI

struct TopNav: View {
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Text("raem")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.deepNavy)
                
                Spacer()
                
                Image("mypage")
                    .resizable()
                    .frame(width: 35, height: 35)
            }
            .globalPadding()
            .padding(.top, geometry.size.height * 0.08)  // 화면 높이에 비례하여 상단 패딩 조정

        }
    }
}

struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopNav()
            .previewLayout(.sizeThatFits)
    }
}
