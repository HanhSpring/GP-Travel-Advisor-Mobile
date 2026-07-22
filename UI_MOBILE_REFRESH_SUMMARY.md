# Tổng kết cải tiến UI — Quản lý chi phí

Tài liệu này mô tả các thay đổi giao diện đã thực hiện cho màn **Quản lý chi phí** của GP Travel Advisor Mobile.

## 1. Mục tiêu

- Làm giao diện quản lý chi phí hiện đại, sang và dễ sử dụng hơn.
- Tăng khả năng đọc nhanh các thông tin tài chính quan trọng.
- Phân tách rõ tổng quan, kế hoạch chi phí, phân bổ thành viên và lịch sử chi tiêu.
- Giữ nguyên toàn bộ nghiệp vụ, dữ liệu và hành vi hiện tại của màn hình.

## 2. Phạm vi thay đổi

Các file được chỉnh sửa:

- `lib/features/itinerary/presentation/screens/incurred_costs_screen.dart`
- `lib/core/theme/app_colors.dart`

Ảnh preview:

- `expense-management-ui-preview.png`

Không chỉnh sửa repository, entity, model, API, backend hoặc bottom sheet thêm/sửa chi phí.

## 3. Tổng quan giao diện mới

### 3.1. App bar

- Giữ tiêu đề **Quản lý chi phí** ở giữa màn hình.
- Tăng độ đậm của tiêu đề để tạo phân cấp thị giác rõ hơn.
- Đồng bộ nền và màu chữ với hệ màu premium của ứng dụng.
- Không sử dụng elevation khi cuộn để giao diện gọn và liền mạch.

### 3.2. Hero tổng quan chi phí

Bổ sung một card tổng quan nổi bật ở đầu màn hình với gradient navy–blue.

Card hiển thị trực tiếp các dữ liệu đã có từ `CostBreakdownEntity`:

- Tổng ước tính cả nhóm đã gồm 10% dự trù.
- Số tiền đã chi đến hiện tại.
- Hạn mức có thể chi trả của cả nhóm.

Các con số được sắp xếp theo mức độ quan trọng, trong đó tổng ước tính là thông tin nổi bật nhất. Hai chỉ số phụ được đặt trong một vùng nền trong suốt nhẹ để dễ so sánh.

Không bổ sung công thức hoặc tự tính lại dữ liệu ở UI.

### 3.3. Phân chia nội dung thành các section

Nội dung được chia thành ba section rõ ràng:

1. **Kế hoạch chuyến đi** — dự toán và hạn mức của cả nhóm.
2. **Phân bổ thành viên** — số tiền mỗi thành viên chịu trách nhiệm.
3. **Lịch sử chi tiêu** — các khoản chi đã được ghi nhận.

Mỗi section có tiêu đề và mô tả ngắn giúp người dùng hiểu nội dung trước khi đọc các con số chi tiết.

## 4. Card kế hoạch chuyến đi

- Đổi cách trình bày thành card trắng, bo góc lớn và có viền xanh-xám nhẹ.
- Bổ sung bóng đổ navy rất nhẹ để tạo chiều sâu nhưng không làm giao diện nặng.
- Làm nổi bật hạn mức có thể chi trả của cả nhóm.
- Giữ nguyên công thức hiển thị số người lớn, trẻ em và đơn giá tương ứng.
- Giữ nguyên `ExpansionTile` để người dùng xem chi tiết:
  - Địa điểm và ăn uống.
  - Lưu trú.
  - Xăng xe/tự túc.
  - Phí dự trù 10%.
- Giữ nguyên mô tả tỷ lệ chi phí trẻ em và đơn giá xăng xe theo kilomet.

## 5. Card phân bổ thành viên

- Bổ sung icon nhận diện cho khu vực thành viên.
- Cải thiện typography của tiêu đề, tên thành viên và số tiền.
- Giữ đường phân cách nhẹ giữa từng thành viên để tránh đọc nhầm dữ liệu.
- Giữ nguyên các thông tin:
  - Tổng tiền thành viên phải trả.
  - Phần chi phí trẻ em mà thành viên phụ trách.
  - Chi tiết chi phí phát sinh theo từng loại.
  - Nhãn chủ lịch trình.

Không thay đổi cách backend phân bổ chi phí cho từng người.

## 6. Lịch sử chi tiêu

### 6.1. Tiêu đề và số lượng

- Đổi tiêu đề mặc định thành **Lịch sử chi tiêu**.
- Hiển thị số khoản chi đã ghi nhận từ độ dài danh sách hiện tại.
- Khi đang lọc theo ngày hoặc địa điểm, tiêu đề tiếp tục phản ánh đúng bộ lọc.

### 6.2. Item chi phí

Mỗi khoản chi được trình bày thành một card riêng với:

- Icon loại chi phí.
- Tên khoản chi.
- Loại chi phí.
- Địa điểm nếu có.
- Người chịu khoản chi.
- Số tiền.
- Nút sửa/xóa hoặc sửa giá khi người dùng có quyền.

Màu và icon được phân loại trực quan:

| Loại chi phí | Màu nhận diện | Icon |
| --- | --- | --- |
| Nước uống | Xanh dương | Ly nước |
| Quà tặng | Hổ phách | Hộp quà |
| Mua sắm | Hổ phách | Túi mua sắm |
| Phí gửi xe | Xám xanh | Ký hiệu đỗ xe |
| Chi phí kế hoạch | Xanh teal | Tuyến đường |
| Điều chỉnh giá | Đỏ nhạt | Thay đổi giá |
| Điều chỉnh xăng xe | Đỏ nhạt | Trạm xăng |
| Khác | Xám xanh | Hóa đơn |

Các mapping màu và icon chỉ phục vụ trình bày, không thay đổi `CostType` hoặc dữ liệu gửi lên backend.

### 6.3. Nhóm chi phí theo ngày

- Giữ nguyên cách gom và sắp xếp chi phí theo ngày.
- Làm nổi bật tiêu đề ngày bằng chấm màu mint và subtotal bên phải.
- Không thay đổi thuật toán xác định ngày từ `placeId` hoặc `dayNumber`.

## 7. Bộ lọc

- Giữ nguyên bộ lọc theo ngày và địa điểm.
- Đổi banner bộ lọc sang nền xanh nhạt, viền nhẹ và bo góc lớn hơn.
- Tăng vùng bấm của thao tác **Xem tất cả** bằng `InkWell` và padding.
- Giữ nguyên hành vi xóa bộ lọc và tải lại dữ liệu.

## 8. Trạng thái giao diện

### Loading

- Đồng bộ màu vòng loading với `AppColors.premiumBlue`.

### Lỗi

- Thay dòng lỗi đơn giản bằng trạng thái lỗi đầy đủ gồm icon, tiêu đề, nội dung lỗi và nút **Thử lại**.
- Nút thử lại tiếp tục gọi `_load()` như luồng tải dữ liệu hiện có.

### Danh sách rỗng

- Bổ sung empty-state dạng card với icon và thông điệp tương ứng.
- Nội dung thay đổi phù hợp khi đang xem toàn bộ, lọc theo ngày hoặc lọc theo địa điểm.

### Lịch trình hoàn thành

- Giữ nguyên banner khóa và điều kiện không cho thêm/sửa/xóa.
- Chỉ cải thiện màu, viền và bo góc của banner.

## 9. Nút thêm chi phí

- Giữ dạng `FloatingActionButton.extended`.
- Sử dụng nền navy, chữ trắng và bo góc `18px`.
- Tăng độ nổi vừa phải để nút dễ nhận biết.
- Giữ nguyên điều kiện ẩn nút khi lịch trình đã hoàn thành.
- Giữ nguyên hành vi mở `IncurredCostSheet`.

## 10. Token màu được bổ sung

Các token sau được thêm vào `AppColors`:

| Token | Mã màu | Mục đích |
| --- | --- | --- |
| `costHeroStart` | `#0B315F` | Điểm đầu gradient hero |
| `costHeroEnd` | `#176BBD` | Điểm cuối gradient hero |
| `costMint` | `#35D0BA` | Điểm nhấn tích cực |
| `costSoftMint` | `#E8F8F4` | Nền icon/card xanh mint |
| `costSoftAmber` | `#FFF7E7` | Nền cảnh báo hoặc icon hổ phách |
| `costAmber` | `#D98412` | Điểm nhấn hổ phách |
| `costDanger` | `#D34B4B` | Thao tác xóa và điều chỉnh |
| `costSoftDanger` | `#FFEEEE` | Nền trạng thái lỗi/điều chỉnh |
| `costText` | `#102A43` | Chữ chính trên màn chi phí |
| `costTextMuted` | `#6C7F95` | Chữ mô tả và metadata |

Việc dùng token giúp tránh lặp lại màu trực tiếp trong widget và dễ đồng bộ giao diện về sau.

## 11. Những phần được giữ nguyên

- `_load()` và toàn bộ lời gọi repository.
- Lấy danh sách chi phí và cost breakdown.
- Lọc theo địa điểm và ngày.
- Cách gom chi phí theo ngày.
- Kiểm tra quyền sửa/xóa của chủ lịch trình và thành viên.
- Điều kiện khóa khi lịch trình hoàn thành.
- Luồng thêm, sửa, sửa giá và xóa chi phí.
- Dialog xác nhận xóa.
- `IncurredCostSheet`.
- Công thức người lớn, trẻ em, lưu trú, xăng xe và dự trù.
- Entity, model, API contract và backend.

## 12. Kiểm tra

Đã chạy:

```bash
dart format \
  lib/core/theme/app_colors.dart \
  lib/features/itinerary/presentation/screens/incurred_costs_screen.dart

flutter analyze \
  lib/features/itinerary/presentation/screens/incurred_costs_screen.dart \
  lib/core/theme/app_colors.dart
```

Kết quả:

```text
No issues found!
```

Chưa chạy build theo yêu cầu.

## 13. Preview

Ảnh preview được tạo để minh họa định hướng giao diện sau khi chỉnh:

`expense-management-ui-preview.png`

Ảnh preview không được sử dụng làm asset runtime và không ảnh hưởng đến ứng dụng.
