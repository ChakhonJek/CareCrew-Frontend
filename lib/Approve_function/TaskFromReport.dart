import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myjek/Approve_function/ReportInfo.dart';
import 'package:myjek/Dashboard/Models.dart';

class Taskfromreport extends StatefulWidget {
  final int personnelId;
  const Taskfromreport({super.key, required this.personnelId});

  @override
  State<Taskfromreport> createState() => _TaskfromreportState();
}

class _TaskfromreportState extends State<Taskfromreport> {
  @override
  void initState() {
    super.initState();
    fetchTaskDetails();
  }

  Future<List<ReportModel>> fetchTaskDetails() async {
    final res = await http.get(Uri.parse("https://api.lcadv.online/api/greport"));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } else {
      throw Exception("โหลดข้อมูลไม่สำเร็จ");
    }
  }

  Future<void> refreshData() async {
    setState(() {});
  }

  Widget reportCard(BuildContext context, ReportModel report) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            report.reportId.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("หมายเลขผู้แจ้ง: ${report.personnelid ?? 0}"),
            Text("สถานที่: ${report.location.isNotEmpty ? report.location : '-'}"),
            const SizedBox(height: 5),
            Text("วันที่: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt.toLocal())}"),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportInfopage(reportModel: report, personnelid: widget.personnelId),
            ),
          );

          if (result == true) {
            refreshData();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการแจ้งเหตุสร้างงาน"),
        backgroundColor: Colors.lightBlue,
        elevation: 2,
      ),
      drawer: AppDrawer(personnelId: widget.personnelId),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<List<ReportModel>>(
          future: fetchTaskDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
                ],
              );
            } else if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: 400,
                    child: Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}")),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 400,
                    child: Center(
                      child: Text(
                        "ยังไม่มีรายงาน",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }

            final reports = snapshot.data!;

            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return reportCard(context, reports[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
