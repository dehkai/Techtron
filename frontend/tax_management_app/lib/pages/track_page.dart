import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'upload_bank_statement_page.dart';
import 'upload_receipt_page.dart';

class CardData {
  final String title;
  final String cardIcon;
  final Color cardBGColor;
  final String totalPrice;

  CardData({required this.title, required this.cardIcon, required this.cardBGColor, required this.totalPrice});
}

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  // Simulate upload status for each month (replace with your real data source)
  final Map<int, String?> _bankStatementFiles = {}; // monthNum -> fileName or null

  // Card data list
  final List<CardData> cardDataList = [
    CardData(title: "My Profile", cardIcon: "icons/ic_profile.png", cardBGColor: const Color(0xff5E5BDB), totalPrice: "RM 0.00"),
    CardData(title: "Sbi Debit Card", cardIcon: "icons/ic_discoverCard.png", cardBGColor: const Color(0xffFF1681), totalPrice: "RM 123.45"),
    CardData(title: "HDFC", cardIcon: "icons/ic_visaCard.png", cardBGColor: const Color(0xffFFBB50), totalPrice: "RM 88.00"),
    CardData(title: "KOTAK", cardIcon: "icons/ic_rupayCard.png", cardBGColor: const Color(0xff311B92), totalPrice: "RM 45.60"),
    CardData(title: "UNI", cardIcon: "icons/ic_americanExpressCard.png", cardBGColor: const Color(0xff6200EA), totalPrice: "RM 210.00"),
    CardData(title: "ONE CARD", cardIcon: "icons/ic_oneCard.png", cardBGColor: const Color(0xffF92752), totalPrice: "RM 67.80"),
    CardData(title: "Sbi Debit Card", cardIcon: "icons/ic_discoverCard.png", cardBGColor: const Color(0xffFF1681), totalPrice: "RM 99.99"),
    CardData(title: "HDFC", cardIcon: "icons/ic_visaCard.png", cardBGColor: const Color(0xffFFBB50), totalPrice: "RM 34.20"),
    CardData(title: "KOTAK", cardIcon: "icons/ic_rupayCard.png", cardBGColor: const Color(0xff311B92), totalPrice: "RM 120.00"),
    CardData(title: "UNI", cardIcon: "icons/ic_americanExpressCard.png", cardBGColor: const Color(0xff6200EA), totalPrice: "RM 56.70"),
    CardData(title: "ONE CARD", cardIcon: "icons/ic_oneCard.png", cardBGColor: const Color(0xffF92752), totalPrice: "RM 12.34"),
  ];

  double overscrollAmount = 0.0;

  void _goToPreviousYear() {
    setState(() {
      _selectedYear--;
    });
  }

  void _goToNextYear() {
    setState(() {
      _selectedYear++;
    });
  }

  void _onMonthSelected(int month) {
    setState(() {
      _selectedMonth = month;
    });
  }

  void _showFullCardImage(BuildContext context, CardData card) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  "images/img_card.png",
                  fit: BoxFit.contain,
                  color: card.cardBGColor.withOpacity(0.8),
                  colorBlendMode: BlendMode.srcATop,
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Expenses', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00303D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Color(0xffF2F1F3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YearSelector(selectedYear: _selectedYear, onPrevious: _goToPreviousYear, onNext: _goToNextYear),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadBankStatementPage()));
                      },
                      icon: const Icon(Icons.account_balance),
                      label: const Text('Upload Bank Statement'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadReceiptPage()));
                      },
                      icon: const Icon(Icons.receipt),
                      label: const Text('Upload Receipt'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              MonthSegments(selectedMonth: _selectedMonth, onMonthSelected: _onMonthSelected),
              const SizedBox(height: 24),
              BankStatementStatus(
                fileName: _bankStatementFiles[_selectedMonth],
                onView: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadReceiptPage()));
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is OverscrollNotification && notification.overscroll < 0) {
                      setState(() {
                        overscrollAmount = (-notification.overscroll).clamp(0, 100); // Limit max expansion
                      });
                    } else if (notification is ScrollEndNotification) {
                      setState(() {
                        overscrollAmount = 0;
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        children:
                            cardDataList.asMap().entries.map((entry) {
                              int index = entry.key;
                              CardData item = entry.value;
                              double cardHeight = 220;
                              // Only expand the top card
                              if (index == 0) cardHeight += overscrollAmount;
                              return Padding(
                                padding: EdgeInsets.only(top: index * 70.0),
                                child: GestureDetector(
                                  onTap: () => _showFullCardImage(context, item),
                                  child: SizedBox(
                                    height: cardHeight,
                                    width: double.infinity,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Image.asset(
                                          "images/img_card.png",
                                          fit: BoxFit.fill,
                                          color: item.cardBGColor.withOpacity(0.8),
                                          colorBlendMode: BlendMode.srcATop,
                                          width: double.infinity,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Column(
                                            children: [
                                              Container(
                                                height: 4,
                                                width: 30,
                                                decoration: BoxDecoration(color: item.cardBGColor, borderRadius: BorderRadius.circular(2)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 20),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                    Text(
                                                      item.totalPrice,
                                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Add more content here if needed
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YearSelector extends StatelessWidget {
  final int selectedYear;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const YearSelector({super.key, required this.selectedYear, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious, splashRadius: 20),
          Text('$selectedYear', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext, splashRadius: 20),
        ],
      ),
    );
  }
}

class MonthSegments extends StatelessWidget {
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  MonthSegments({super.key, required this.selectedMonth, required this.onMonthSelected});

  // List of months from August to July
  static const List<String> months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(12, (index) {
          // Calculate month number: August is 8, ..., July is 7
          int monthNum = (index + 8) > 12 ? (index + 8) - 12 : (index + 8);
          bool isSelected = selectedMonth == monthNum;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(label: Text(months[index]), selected: isSelected, onSelected: (_) => onMonthSelected(monthNum)),
          );
        }),
      ),
    );
  }
}

class BankStatementStatus extends StatelessWidget {
  final String? fileName;
  final VoidCallback onView;

  const BankStatementStatus({super.key, required this.fileName, required this.onView});

  @override
  Widget build(BuildContext context) {
    if (fileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bank statement uploaded: $fileName', style: const TextStyle(color: Colors.green)),
            TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility), label: const Text('View')),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
        child: const Text('You have not submitted your bank statement for this month.', style: TextStyle(color: Colors.red)),
      );
    }
  }
}

class ReceiptCard extends StatelessWidget {
  final String merchant;
  final String date;
  final String amount;
  final Color color;

  const ReceiptCard({super.key, required this.merchant, required this.date, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipPath(
        clipper: WalletNotchClipper(),
        child: Container(
          height: 120,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(merchant, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date, style: const TextStyle(color: Colors.white70)),
                  Text(amount, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom clipper for the notch effect
class WalletNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 24.0;
    final path = Path();
    path.moveTo(0, notchRadius);
    path.quadraticBezierTo(0, 0, notchRadius, 0);
    path.lineTo(size.width - notchRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, notchRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
