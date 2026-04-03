import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MÀN HÌNH CHÍNH (MENU 4 NÚT) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GIA DỤNG MỸ LỆ"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _menuCard(context, "TẠO ĐƠN", Icons.add_shopping_cart, const Color(0xFF2980b9), const SaleScreen()),
            _menuCard(context, "CÔNG NỢ", Icons.monetization_on, const Color(0xFFe74c3c), const DebtScreen()),
            _menuCard(context, "SẢN PHẨM", Icons.inventory_2, const Color(0xFFf39c12), const ProductScreen()),
            _menuCard(context, "IN TEM", Icons.print, const Color(0xFF27ae60), const PrintScreen()),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, Color color, Widget? screen) {
    return InkWell(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH TẠO ĐƠN ---
class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});
  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final String serverUrl = "http://192.168.1.110:5000"; 

  final _khachController = TextEditingController();
  final _searchController = TextEditingController();
  final _slController = TextEditingController();
  final _noCuController = TextEditingController();
  final _phuThuController = TextEditingController();
  final _giamGiaController = TextEditingController();
  final _ghiChuController = TextEditingController();
  
  final fmt = NumberFormat("#,###", "vi_VN");
  TextEditingController? _autoCompleteSaleCtrl;

  List allProducts = [];
  List filteredProducts = [];
  List allCustomers = [];
  List filteredCustomers = [];
  List cart = [];
  
  double tongTien = 0;
  dynamic selectedProduct;
  String trangThai = "Đã thu tiền";

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      final resP = await http.get(Uri.parse("$serverUrl/api/products")).timeout(const Duration(seconds: 5));
      final resC = await http.get(Uri.parse("$serverUrl/api/customers")).timeout(const Duration(seconds: 5));
      
      if (resP.statusCode == 200) setState(() { allProducts = jsonDecode(resP.body); });
      if (resC.statusCode == 200) setState(() { allCustomers = jsonDecode(resC.body); });
    } catch (e) {
      debugPrint("Lỗi kết nối: $e");
    }
  }

  void selectCustomer(dynamic c) {
    setState(() {
      _khachController.text = c['ten'];
      _noCuController.text = fmt.format(c['no_cu'] ?? 0);
      filteredCustomers = [];
      tinhTongTien();
    });
  }

  void selectProduct(dynamic p) {
    setState(() {
      selectedProduct = p;
      _searchController.text = p['ten'];
      filteredProducts = [];
      _slController.text = "1";
    });
  }

  void addToCart() {
    if (selectedProduct == null) {
      _showMsg("Vui lòng chọn sản phẩm từ gợi ý!");
      return;
    }
    double sl = double.tryParse(_slController.text) ?? 1.0;
    setState(() {
      double sl = double.tryParse(_slController.text) ?? 1.0;

      int index = cart.indexWhere((it) => it['id'] == selectedProduct['id']);

      if (index != -1) {
        // Đã tồn tại → cộng dồn số lượng
        cart[index]['sl'] = (cart[index]['sl'] ?? 0) + sl;
      } else {
        // Chưa có → thêm mới
        cart.add({
          'id': selectedProduct['id'],
          'ten': selectedProduct['ten'],
          'gia': selectedProduct['gia_ban'],
          'sl': sl
        });
      }

      tinhTongTien();
      selectedProduct = null;
      _autoCompleteSaleCtrl?.clear(); // <--- Dùng biến mới này thay cho _searchController
      _slController.text = "1";       // (Hoặc .clear() tùy ý bạn, nhưng nên để "1" cho tiện bán hàng)
    });
  }

  void removeFromCart(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: Text("Xóa '${cart[index]['ten']}' khỏi giỏ hàng?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          TextButton(
            onPressed: () {
              setState(() { cart.removeAt(index); tinhTongTien(); });
              Navigator.pop(context);
            }, 
            child: const Text("XÓA", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // Sửa trong hàm tinhTongTien() của main.dart
  void tinhTongTien() {
    double hang = 0;
    for (var it in cart) {
      hang += (it['gia'] ?? 0) * (it['sl'] ?? 0);
    }

    // Xóa dấu phẩy và dấu chấm trước khi parse
    double phu = double.tryParse(_phuThuController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    double giam = double.tryParse(_giamGiaController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    double nocu = double.tryParse(_noCuController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;

    setState(() {
      // tongTien này là con số khách thực trả (Đơn mới + Nợ cũ)
      tongTien = hang + phu - giam + nocu;
    });
  }

  void _showMsg(String txt) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
  }

  Future<void> guiDonHang(bool coIn) async {
    if (cart.isEmpty) { _showMsg("Giỏ hàng trống!"); return; }
    
    String tenKhach = _khachController.text.trim();
    if (trangThai == "Chưa thu tiền" && (tenKhach == "" || tenKhach == "Khách lẻ")) {
      _showMsg("Vui lòng nhập tên khách để ghi nợ!");
      return;
    }
    if (tenKhach == "") tenKhach = "Khách lẻ";

    // --- LOGIC SỬA ĐỔI TẠI ĐÂY ---
    // Tính toán tiền hàng của đơn mới
    double tienHangThucTe = 0;
    for (var item in cart) {
      tienHangThucTe += (item['gia'] ?? 0) * (item['sl'] ?? 0);
    }
    
    double phu = double.tryParse(_phuThuController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    double giam = double.tryParse(_giamGiaController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    double nocu = double.tryParse(_noCuController.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;

    // 1. Tiền của riêng hóa đơn này (Gửi vào cột tong_tien trong 13.py)
    double donHangMoi = tienHangThucTe + phu - giam;
    
    // 2. Tổng cộng cuối cùng (Gửi để in ra bill)
    double tongThanhToan = donHangMoi + nocu;

    try {
      final res = await http.post(
        Uri.parse("$serverUrl/api/orders"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "khach": tenKhach,
          "cart": {for (var item in cart) item['id'].toString(): {"ten": item['ten'], "gia": item['gia'], "sl": item['sl']}},
          "phu_thu": phu,
          "giam_gia": giam,
          "tong": donHangMoi,      // Chỉ gửi tiền đơn mới để tránh lặp nợ
          "no_cu": nocu,           // Thêm tham số này để 13.py nhận diện
          "tong_thu": tongThanhToan, // Thêm tham số này để in Bill từ App chuẩn
          "status": trangThai,
          "ghi_chu": _ghiChuController.text,
          "print_now": coIn
        }),
      );
      if (res.statusCode == 200) {
        _showMsg("✅ Đã lưu đơn hàng!");
        resetForm();
      }
    } catch (e) { _showMsg("❌ Lỗi: $e"); }
  }

  void resetForm() {
    setState(() {
      _khachController.clear(); _searchController.clear(); _slController.clear();
      _noCuController.clear(); _phuThuController.clear(); _giamGiaController.clear(); _ghiChuController.clear();
      cart = []; tongTien = 0; trangThai = "Đã thu tiền";
    });
    loadInitialData(); // Load lại nợ cũ mới nhất
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TẠO ĐƠN HÀNG"), 
        backgroundColor: const Color(0xFF2c3e50), 
        foregroundColor: Colors.white
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // --- 1. KHU VỰC TÌM KHÁCH HÀNG (GIỮ NGUYÊN) ---
                  Stack(children: [
                    _buildInput("Tên khách hàng", _khachController, icon: Icons.person, onChanged: (val) {
                      setState(() {
                        if (val.isEmpty) {
                          filteredCustomers = [];
                        } else {
                          filteredCustomers = allCustomers.where((c) => 
                            c['ten'].toString().toLowerCase().contains(val.toLowerCase())
                          ).toList();
                        }
                      });
                    }),
                    if (filteredCustomers.isNotEmpty)
                      _buildOverlayList(filteredCustomers, (c) => selectCustomer(c), isCustomer: true),
                  ]),
                  
                  // --- 2. KHU VỰC TÌM SẢN PHẨM & SỐ LƯỢNG (DÙNG AUTOCOMPLETE THÔNG MINH) ---
                  Column(
                    children: [
                      Autocomplete<Map>(
                        displayStringForOption: (option) => "${option['id']} - ${option['ten']} - ${fmt.format(option['gia_ban'] ?? option['gia'] ?? 0)}đ",
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final keyword = textEditingValue.text.trim().toLowerCase();
                          if (keyword.isEmpty) return const Iterable<Map>.empty();
                          
                          final isNumeric = int.tryParse(keyword) != null;
                          return allProducts.where((p) {
                            final tenSP = p['ten'].toString().toLowerCase();
                            final maSP = p['id'].toString().toLowerCase();
                            
                            if (isNumeric) return maSP == keyword; // Tìm chính xác mã
                            return tenSP.contains(keyword) || maSP.contains(keyword); // Tìm theo tên/mã
                          }).cast<Map>();
                        },
                        onSelected: (option) {
                          setState(() {
                            selectedProduct = option;
                            _slController.text = "1"; // Tự động điền số lượng 1
                            FocusScope.of(context).unfocus(); // Hạ bàn phím
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          _autoCompleteSaleCtrl = controller;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Tìm/Quét mã sản phẩm...",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                prefixIcon: Icon(Icons.qr_code_scanner),
                              ),
                            ),
                          );
                        },
                      ),
                      // Ô Nhập số lượng đã được trả lại vị trí
                      _buildInput("Số lượng", _slController, isNumber: true, icon: Icons.exposure),
                    ],
                  ),
                  
                  // --- 3. NÚT THÊM VÀO GIỎ ---
                  ElevatedButton.icon(
                    onPressed: addToCart, 
                    icon: const Icon(Icons.add), 
                    label: const Text("THÊM VÀO GIỎ"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, 
                      foregroundColor: Colors.white, 
                      minimumSize: const Size(double.infinity, 45)
                    )
                  ),

                  // --- 4. CÁC THÔNG TIN KHÁC (Nợ cũ, Phụ thu, Ghi chú...) ---
                  const SizedBox(height: 15),
                  _buildInput("Nợ cũ hiện tại", _noCuController, readOnly: true, icon: Icons.account_balance_wallet, color: Colors.red),
                  
                  _buildDropdown(),
                  
                  const SizedBox(height: 10),
                  _buildInput("Phụ thu (+)", _phuThuController, isNumber: true, icon: Icons.add_circle_outline, onChanged: (_) => tinhTongTien()),
                  _buildInput("Giảm giá (-)", _giamGiaController, isNumber: true, icon: Icons.remove_circle_outline, onChanged: (_) => tinhTongTien()),
                  _buildInput("Ghi chú đơn hàng", _ghiChuController, icon: Icons.note_alt_outlined),
                  
                  const Divider(height: 30),
                  const Text("DANH SÁCH GIỎ HÀNG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16)),
                  
                  // Gọi hàm vẽ giỏ hàng
                  _buildCartList(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildOverlayList(List items, Function(dynamic) onSelect, {bool isCustomer = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blueGrey), boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(items[i]['ten']),
          subtitle: Text(isCustomer ? "Nợ: ${fmt.format(items[i]['no_cu'])}" : "Giá: ${fmt.format(items[i]['gia_ban'])} - Tồn: ${items[i]['sl']}"),
          onTap: () => onSelect(items[i]),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: trangThai, isExpanded: true,
          items: ["Đã thu tiền", "Chưa thu tiền"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => trangThai = v!),
        ),
      ),
    );
  }

// --- HÀM CHỈNH SỬA SẢN PHẨM TRONG GIỎ HÀNG ---
  void _editCartItem(int index) {
    final item = cart[index];

    // Xử lý làm sạch đuôi .0 cho số lượng
    double sl = double.tryParse(item['sl'].toString()) ?? 1.0;
    String slHienThi = (sl == sl.toInt()) ? sl.toInt().toString() : sl.toString();
    TextEditingController editSlCtrl = TextEditingController(text: slHienThi);

    // Xử lý làm sạch đuôi .0 cho giá bán (phòng trường hợp giá bị lưu là 10000.0)
    double gia = double.tryParse(item['gia'].toString()) ?? 0;
    String giaHienThi = (gia == gia.toInt()) ? gia.toInt().toString() : gia.toString();
    TextEditingController editGiaCtrl = TextEditingController(text: giaHienThi);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Chỉnh sửa: ${item['ten']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editSlCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // Hỗ trợ gõ dấu phẩy/chấm
                decoration: const InputDecoration(labelText: "Số lượng", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: editGiaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Giá bán (đ)", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Hủy", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60), foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  // Cập nhật lại số lượng và giá mới vào giỏ hàng
                  cart[index]['sl'] = double.tryParse(editSlCtrl.text) ?? item['sl'];
                  cart[index]['gia'] = double.tryParse(editGiaCtrl.text) ?? item['gia'];
                  tinhTongTien(); // Tính lại tổng tiền của cả đơn
                });
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: const Text("LƯU"),
            ),
          ],
        );
      }
    );
  }

  // --- HÀM VẼ GIỎ HÀNG CÓ NÚT XÓA TRỰC QUAN ---
  // --- HÀM VẼ GIỎ HÀNG (AN TOÀN & CHUẨN XÁC) ---
  Widget _buildCartList() {
    // Khai báo biến định dạng tiền tệ ở ngay trong hàm
    final fmt = NumberFormat("#,###", "vi_VN"); 

    if (cart.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Giỏ hàng đang trống", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
      );
    }

    return ListView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      itemCount: cart.length,
      itemBuilder: (context, index) {
        final item = cart[index];
        
        // 1. Ép kiểu an toàn (Tránh lỗi dynamic của Flutter)
        final String tenSP = item['ten']?.toString() ?? "Sản phẩm";
        final int sl = int.tryParse(item['sl'].toString()) ?? 1;
        final double gia = double.tryParse(item['gia'].toString()) ?? 0;
        
        // 2. Làm phép tính ở ngoài Widget
        final double thanhTien = sl * gia;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          child: ListTile(
            onTap: () => _editCartItem(index), // Chạm để sửa
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            
            // 3. Đưa dữ liệu đã sạch sẽ vào Text
            title: Text(tenSP, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              "✏️ $sl x ${fmt.format(gia)} đ  =  ${fmt.format(thanhTien)} đ",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
            
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: "Xóa khỏi giỏ",
              onPressed: () {
                setState(() {
                  cart.removeAt(index); 
                  tinhTongTien();       
                });
              },
            ),
          ),
        );
      },
    );
  }
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("TỔNG THANH TOÁN:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text("${fmt.format(tongTien)}đ", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () => guiDonHang(true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2980b9), foregroundColor: Colors.white), child: const Text("XÁC NHẬN & IN"))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(onPressed: () => guiDonHang(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white), child: const Text("LƯU ĐƠN"))),
        ])
      ]),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {bool isNumber = false, IconData? icon, Function(String)? onChanged, bool readOnly = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl, readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        style: TextStyle(color: color, fontWeight: readOnly ? FontWeight.bold : FontWeight.normal),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

// -------PHẦN CÔNG NỢ-----
class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});
  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final String serverUrl = "http://192.168.1.110:5000"; // Đảm bảo trùng IP với SaleScreen
  List allDebts = [];
  List filteredDebts = [];
  bool isLoading = true;
  final _searchController = TextEditingController();
  final fmt = NumberFormat("#,###", "vi_VN");

  @override
  void initState() {
    super.initState();
    fetchDebts();
  }

  Future<void> fetchDebts() async {
    try {
      final res = await http.get(Uri.parse("$serverUrl/api/debt"));
      if (res.statusCode == 200) {
        setState(() {
          allDebts = jsonDecode(res.body);
          filteredDebts = allDebts;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  void filterDebts(String query) {
    setState(() {
      filteredDebts = allDebts
          .where((d) => d['khach'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  double calculateTotal() {
    return filteredDebts.fold(0, (sum, item) => sum + ((item['tong_thu'] ?? item['tong']) ?? 0));
  }

  Future<void> confirmPayment(int id, String name) async {
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: Text("Hóa đơn #$id của '$name' đã thanh toán xong?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await http.put(
        Uri.parse("$serverUrl/api/debt"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );
      if (res.statusCode == 200) {
        fetchDebts(); // Tải lại danh sách
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã cập nhật trạng thái đơn hàng")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("QUẢN LÝ CÔNG NỢ"),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER: TỔNG CỘNG & NÚT QUAY LẠI ---
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              children: [
                const Text("Danh Sách Nợ Khách", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                Text("Tổng cộng: ${fmt.format(calculateTotal())} VNĐ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                // --- THANH LỌC TÊN KHÁCH HÀNG ---
                TextField(
                  controller: _searchController,
                  onChanged: filterDebts,
                  decoration: InputDecoration(
                    hintText: "Lọc theo tên khách hàng...",
                    prefixIcon: const Icon(Icons.filter_list),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          
          // --- LIST: DANH SÁCH HÓA ĐƠN NỢ ---
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredDebts.isEmpty 
                ? const Center(child: Text("Không có dữ liệu nợ khớp với tìm kiếm"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredDebts.length,
                    itemBuilder: (context, i) {
                      final d = filteredDebts[i];
                      return _buildDebtCard(d);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(dynamic d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Vạch đỏ bên trái như ảnh mẫu
            Container(width: 6, decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(d['khach'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2c3e50))),
                      Text("#${d['id']}", style: const TextStyle(color: Colors.grey)),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(d['ngay'], style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text("${fmt.format(d['tong_thu'] ?? d['tong'])} đ", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ]),
                    const SizedBox(height: 15),
                    // --- NÚT HÀNH ĐỘNG CHIA LÀM 2 ---
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Thêm lệnh chuyển màn hình và truyền dữ liệu đơn hàng (biến 'd')
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(order: d)
                                )
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey, 
                              foregroundColor: Colors.white, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: const Text("CHI TIẾT"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => confirmPayment(d['id'], d['khach']),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ecc71), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("THU TIỀN XONG"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//---MÀN HÌNH CHI TIẾT ĐƠN TRONG CÔNG NỢ---
class OrderDetailScreen extends StatelessWidget {
  final dynamic order; // Nhận dữ liệu đơn hàng từ màn hình trước
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat("#,###", "vi_VN");
    
    // Giải mã chi tiết giỏ hàng
    Map<String, dynamic> items = {};
    try {
      if (order['chi_tiet'] is String) {
        items = jsonDecode(order['chi_tiet']);
      } else {
        items = order['chi_tiet'];
      }
    } catch (e) {
      items = {};
    }

    // Tính toán Tổng tiền hàng gốc (chưa cộng trừ phụ phí)
    double tienHang = 0;
    items.forEach((key, val) {
      tienHang += (val['gia'] ?? 0).toDouble() * (val['sl'] ?? 0).toDouble();
    });

    // Lấy các tham số từ Server (nếu không có thì mặc định là 0)
    double phuThu = (order['phu_thu'] ?? 0).toDouble();
    double giamGia = (order['giam_gia'] ?? 0).toDouble();
    double tienDonNay = (order['tong'] ?? 0).toDouble();
    double noCu = (order['no_cu'] ?? 0).toDouble();
    double tongThanhToan = (order['tong_thu'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Chi tiết HĐ #${order['id']}"),
        backgroundColor: const Color(0xFF2c3e50),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 1. THÔNG TIN CHUNG ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MÃ HÓA ĐƠN: ${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Khách hàng: ${order['khach']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Ngày giờ: ${order['ngay']}"),
                const Text("Trạng thái: Chưa thu tiền", style: TextStyle(color: Colors.red)),
                if (order['ghi_chu'] != null && order['ghi_chu'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text("Ghi chú: ${order['ghi_chu']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          
          // --- 2. DANH SÁCH MÓN HÀNG ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(children: [
              Expanded(flex: 3, child: Text("Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              Expanded(child: Text("SL", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              Expanded(flex: 2, child: Text("Thành tiền", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  String key = items.keys.elementAt(index);
                  var val = items[key];
                  double subtotal = (val['gia'] ?? 0).toDouble() * (val['sl'] ?? 0).toDouble();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3, 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${val['ten']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 3),
                              Text("Đơn giá: ${fmt.format(val['gia'])}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ]
                          )
                        ),
                        Expanded(child: Text("${val['sl']}", textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text(fmt.format(subtotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // --- 3. BẢNG TỔNG KẾT (KHỚP VỚI MÁY TÍNH) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Column(
              children: [
                _buildSummaryRow("Tổng tiền hàng:", tienHang),
                if (phuThu > 0) _buildSummaryRow("Phụ thu (+):", phuThu),
                if (giamGia > 0) _buildSummaryRow("Giảm giá (-):", giamGia),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(color: Colors.grey, thickness: 1), // Đã xóa style, thêm thickness nếu muốn nét rõ hơn
                ),

                _buildSummaryRow("TIỀN ĐƠN NÀY:", tienDonNay, isBold: true),
                if (noCu > 0) _buildSummaryRow("Nợ cũ mang sang:", noCu),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.black87, thickness: 1.5), // Dấu gạch đậm ngăn cách tổng cộng
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text("TỔNG THANH TOÁN:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("${fmt.format(tongThanhToan)} đ", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                  ]
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Hàm hỗ trợ vẽ từng dòng trong bảng tính tiền
  Widget _buildSummaryRow(String label, dynamic value, {bool isBold = false}) {
    final fmt = NumberFormat("#,###", "vi_VN");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black : Colors.blueGrey)), 
          Text(fmt.format(value), style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))
        ],
      ),
    );
  }
}

//----CHỨC NĂNG SẢN PHẨM----
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final String serverUrl = "http://192.168.1.110:5000"; // Đổi IP nếu cần
  List allProducts = [];
  List filteredProducts = [];
  bool isLoading = true;
  
  final _searchController = TextEditingController();
  
  // Controllers cho hàng nhập liệu nhanh
  final _tenCtrl = TextEditingController();
  final _nhapCtrl = TextEditingController();
  final _banCtrl = TextEditingController();
  final _slCtrl = TextEditingController();

  final fmt = NumberFormat("#,###", "vi_VN");
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final res = await http.get(Uri.parse("$serverUrl/api/products"));
      if (res.statusCode == 200) {
        setState(() {
          allProducts = jsonDecode(res.body);
          // Đảo ngược danh sách để sản phẩm mới thêm hiện lên đầu bảng
          allProducts = allProducts.reversed.toList(); 
          filteredProducts = allProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối máy chủ!")));
    }
  }

  // --- LỌC TÌM KIẾM THÔNG MINH (SMART FILTER) ---
  void filterProducts(String query) {
    final keyword = query.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredProducts = allProducts;
      } else {
        final isNumeric = int.tryParse(keyword) != null;

        filteredProducts = allProducts.where((p) {
          final tenSP = p['ten'].toString().toLowerCase();
          final maSP = p['id'].toString().toLowerCase();

          if (isNumeric) {
            // SỬA Ở ĐÂY: Dùng == thay vì .contains để tìm CHÍNH XÁC ID
            return maSP == keyword; 
          } else {
            return tenSP.contains(keyword) || maSP.contains(keyword);
          }
        }).toList();
      }
    });
  }

  // Thêm sản phẩm từ hàng nhập liệu ngang
  Future<void> addProduct() async {
    if (_tenCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên SP!")));
      return;
    }

    double nhap = double.tryParse(_nhapCtrl.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    double ban = double.tryParse(_banCtrl.text.replaceAll(RegExp(r'[.,]'), '')) ?? 0;
    int sl = int.tryParse(_slCtrl.text) ?? 0;

    final payload = {
      "ten": _tenCtrl.text,
      "gia_nhap": nhap,
      "gia_ban": ban,
      "sl": sl
    };

    final res = await http.post(
      Uri.parse("$serverUrl/api/products"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload)
    );

    if (res.statusCode == 200) {
      _tenCtrl.clear(); _nhapCtrl.clear(); _banCtrl.clear(); _slCtrl.clear();
      fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã thêm sản phẩm mới")));
    }
  }

  // Chỉnh sửa sản phẩm
  void editProduct(Map p) {
    final editTen = TextEditingController(text: p['ten']);
    final editNhap = TextEditingController(text: p['gia_nhap'].toString());
    final editBan = TextEditingController(text: p['gia_ban'].toString());
    final editSl = TextEditingController(text: p['sl'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Sửa sản phẩm #${p['id']}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: editTen, decoration: const InputDecoration(labelText: "Tên sản phẩm")),
              TextField(controller: editNhap, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá Nhập")),
              TextField(controller: editBan, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá Bán")),
              TextField(controller: editSl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          TextButton(
            onPressed: () async {
              final payload = {
                "id": p['id'], // Gửi kèm ID để Server hiểu là lệnh Cập nhật
                "ten": editTen.text,
                "gia_nhap": double.tryParse(editNhap.text) ?? 0,
                "gia_ban": double.tryParse(editBan.text) ?? 0,
                "sl": int.tryParse(editSl.text) ?? 0
              };
              await http.post(Uri.parse("$serverUrl/api/products"), headers: {"Content-Type": "application/json"}, body: jsonEncode(payload));
              Navigator.pop(ctx);
              fetchProducts();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã lưu thay đổi")));
            }, 
            child: const Text("LƯU", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Future<void> deleteProduct(int id) async {
    final confirm = await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Xóa sản phẩm"),
      content: const Text("Chắc chắn xóa sản phẩm này?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("HỦY")),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("XÓA", style: TextStyle(color: Colors.red))),
      ],
    ));

    if (confirm == true) {
      await http.delete(Uri.parse("$serverUrl/api/products"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"id": id}));
      fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(title: const Text("Kho Sản Phẩm"), backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM TRÊN CÙNG
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: filterProducts,
              decoration: InputDecoration(
                hintText: "Tìm tên sản phẩm...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. HÀNG TIÊU ĐỀ (Teal background)
          Container(
            color: const Color(0xFF00796B),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            child: Row(
              children: [
                _buildHeaderCell("ID", 1),
                _buildHeaderCell("Tên SP", 3),
                _buildHeaderCell("Bán", 2),
                _buildHeaderCell("Nhập", 2),
                _buildHeaderCell("SL", 1),
                const Expanded(flex: 1, child: SizedBox()), // Cột trống cho nút Xóa
              ],
            ),
          ),

          // 3. HÀNG NHẬP LIỆU NHANH (Nền màu kem)
          Container(
            color: const Color(0xFFFFF8E1), // Màu kem nhạt như ảnh
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            child: Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()), // ID trống vì tự động
                Expanded(flex: 3, child: _buildCompactInput(_tenCtrl, "")),
                Expanded(flex: 2, child: _buildCompactInput(_banCtrl, "", isNum: true)),
                Expanded(flex: 2, child: _buildCompactInput(_nhapCtrl, "", isNum: true)),
                Expanded(flex: 1, child: _buildCompactInput(_slCtrl, "", isNum: true)),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: addProduct,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 35,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. DANH SÁCH SẢN PHẨM CÓ THANH CUỘN
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true, // Luôn hiện thanh cuộn
                  thickness: 6,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, i) {
                      final p = filteredProducts[i];
                      return InkWell(
                        onTap: () => editProduct(p), // Bấm vào dòng để sửa
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                            child: Row(
                              children: [
                                _buildDataCell(p['id'].toString(), 1, isBold: true),
                                _buildDataCell(p['ten'], 3),
                                _buildDataCell(fmt.format(p['gia_ban']), 2),
                                _buildDataCell(fmt.format(p['gia_nhap']), 2),
                                _buildDataCell(p['sl'].toString(), 1),
                                Expanded(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () => deleteProduct(p['id']),
                                    child: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // --- Các hàm hỗ trợ vẽ giao diện ---
  Widget _buildHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDataCell(String text, int flex, {bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, 
                  style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _buildCompactInput(TextEditingController ctrl, String hint, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }
}
//-----CHỨC NĂN IN TEM NHÃN----
class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final String serverUrl = "http://192.168.1.110:5000"; // Đổi IP nếu cần
  List allProducts = [];
  List printQueue = []; // Bảng chờ in
  bool isLoading = true;

  // Controllers cho phần thêm lẻ
  dynamic selectedProduct;
  TextEditingController? _autoCompleteCtrl;
  final TextEditingController _slTemCtrl = TextEditingController(text: "1");

  // Controllers cho phần dải ID
  final TextEditingController _idACtrl = TextEditingController();
  final TextEditingController _idBCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final res = await http.get(Uri.parse("$serverUrl/api/products"));
      if (res.statusCode == 200) {
        setState(() {
          allProducts = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối tải sản phẩm")));
    }
  }

  // --- THÊM 1 SẢN PHẨM VÀO BẢNG CHỜ ---
  void addSingleToQueue() {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn 1 sản phẩm!")));
      return;
    }
    int sl = int.tryParse(_slTemCtrl.text) ?? 1;
    if (sl <= 0) return;

    setState(() {
      printQueue.add({
        "id": selectedProduct['id'],
        "ten": selectedProduct['ten'],
        "sl_in": sl,
      });
      // Reset sau khi thêm
      selectedProduct = null;
      _slTemCtrl.text = "1";
      _autoCompleteCtrl?.clear(); 
    });
    FocusScope.of(context).unfocus(); // Hạ bàn phím xuống
  }

  // --- THÊM THEO DẢI ID (A đến B) ---
  void addRangeToQueue() {
    if (_idACtrl.text.isEmpty || _idBCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ ID A và ID B!")));
      return;
    }

    String startStr = _idACtrl.text.trim();
    String endStr = _idBCtrl.text.trim();
    
    // Kiểm tra xem ID gõ vào là số hay chữ để so sánh cho chuẩn
    int? startNum = int.tryParse(startStr);
    int? endNum = int.tryParse(endStr);

    List productsToAdd = allProducts.where((p) {
      String pidStr = p['id'].toString();
      
      if (startNum != null && endNum != null) {
        // Nếu ID nhập vào là số (VD: Từ 1 đến 10)
        int? pidNum = int.tryParse(pidStr);
        if (pidNum != null) {
          return pidNum >= startNum && pidNum <= endNum;
        }
        return false;
      } else {
        // Nếu ID có chứa chữ (VD: Từ SP01 đến SP10) -> So sánh chuỗi
        return pidStr.compareTo(startStr) >= 0 && pidStr.compareTo(endStr) <= 0;
      }
    }).toList();

    if (productsToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy sản phẩm nào trong dải ID này!")));
      return;
    }

    setState(() {
      for (var p in productsToAdd) {
        // Lấy số lượng tồn kho (ton_kho hoặc sl tùy cấu trúc DB của bạn) làm số lượng tem
        int tonKho = p['ton_kho'] ?? p['sl'] ?? 1; 
        if (tonKho > 0) {
          printQueue.add({
            "id": p['id'],
            "ten": p['ten'],
            "sl_in": tonKho,
          });
        }
      }
      _idACtrl.clear();
      _idBCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${productsToAdd.length} SP vào chờ in")));
    FocusScope.of(context).unfocus();
  }

  // --- GỬI LỆNH IN LÊN SERVER ---
  Future<void> confirmPrint() async {
    if (printQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bảng chờ in đang trống!")));
      return;
    }

    // Gửi danh sách printQueue lên Server qua API
    // Yêu cầu: File 13.py trên Server phải có endpoint POST /api/print_labels
    try {
      final res = await http.post(
        Uri.parse("$serverUrl/api/print_labels"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"danh_sach_in": printQueue}),
      );

      if (res.statusCode == 200) {
        setState(() => printQueue.clear());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã gửi lệnh in thành công!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Máy chủ từ chối lệnh in!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối đến máy in!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("IN TEM NHÃN"),
        backgroundColor: const Color(0xFF27ae60), // Màu xanh lá đặc trưng cho In ấn
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // --- KHU VỰC 1: TÌM KIẾM VÀ THÊM LẺ ---
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Autocomplete<Map>( // 1. Thay <dynamic> thành <Map>
                        displayStringForOption: (option) => "${option['id']} - ${option['ten']}",
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final keyword = textEditingValue.text.trim().toLowerCase();
                          
                          // 2. Ép kiểu rỗng về Map
                          if (keyword.isEmpty) return const Iterable<Map>.empty(); 
                          
                          final isNumeric = int.tryParse(keyword) != null;
                          return allProducts.where((p) {
                            final tenSP = p['ten'].toString().toLowerCase();
                            final maSP = p['id'].toString().toLowerCase();
                            if (isNumeric) return maSP == keyword;
                            return tenSP.contains(keyword) || maSP.contains(keyword);
                          }).cast<Map>(); // 3. Thêm .cast<Map>() ở cuối
                        },
                        onSelected: (option) => selectedProduct = option,
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          _autoCompleteCtrl = controller;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: "Tìm Tên/ID...",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              prefixIcon: Icon(Icons.search)
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _slTemCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(labelText: "SL Tem", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 0)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: addSingleToQueue,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60), foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                      child: const Icon(Icons.add),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),

              // --- KHU VỰC 2: THÊM THEO DẢI ID ---
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blueGrey[50],
                child: Row(
                  children: [
                    const Text("Dải ID:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _idACtrl,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: "Từ ID A", filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 0)),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.arrow_right_alt, color: Colors.grey)),
                    Expanded(
                      child: TextField(
                        controller: _idBCtrl,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: "Đến ID B", filled: true, fillColor: Colors.white, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 0)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: addRangeToQueue,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                      child: const Icon(Icons.playlist_add),
                    )
                  ],
                ),
              ),

              // --- KHU VỰC 3: BẢNG CHỜ IN ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                color: Colors.grey[300],
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text("Tên sản phẩm", style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text("SL Tem", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 40), // Cân đối với nút xóa
                  ],
                ),
              ),
              Expanded(
                child: printQueue.isEmpty
                  ? const Center(child: Text("Bảng chờ in đang trống", style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      itemCount: printQueue.length,
                      itemBuilder: (context, index) {
                        final item = printQueue[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text(item['id'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text(item['ten'], maxLines: 2, overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 1, child: Text(item['sl_in'].toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () => setState(() => printQueue.removeAt(index)),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),

              // --- KHU VỰC 4: NÚT HÀNH ĐỘNG CUỐI TRANG ---
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        label: const Text("XÓA TẤT CẢ", style: TextStyle(color: Colors.red)),
                        onPressed: () => setState(() => printQueue.clear()),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text("XÁC NHẬN IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: confirmPrint,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27ae60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
    );
  }
}
