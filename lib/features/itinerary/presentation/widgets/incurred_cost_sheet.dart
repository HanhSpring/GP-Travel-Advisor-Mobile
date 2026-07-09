import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

/// Bottom sheet dùng chung để thêm/sửa 1 khoản chi phí phát sinh (mục 1.6).
/// Dùng ở cả 2 nơi: icon tại từng địa điểm (truyền sẵn [initialPlaceId]) và
/// màn "Quản lý chi phí" tổng hợp (để [initialPlaceId] trống).
class IncurredCostSheet extends StatefulWidget {
  final String itineraryId;
  final List<ItineraryMemberEntity> members;
  final String? initialPlaceId;
  final String? initialPlaceName;
  final IncurredCostEntity? editingCost;
  final VoidCallback? onSaved;

  const IncurredCostSheet({
    super.key,
    required this.itineraryId,
    required this.members,
    this.initialPlaceId,
    this.initialPlaceName,
    this.editingCost,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String itineraryId,
    required List<ItineraryMemberEntity> members,
    String? initialPlaceId,
    String? initialPlaceName,
    IncurredCostEntity? editingCost,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncurredCostSheet(
        itineraryId: itineraryId,
        members: members,
        initialPlaceId: initialPlaceId,
        initialPlaceName: initialPlaceName,
        editingCost: editingCost,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<IncurredCostSheet> createState() => _IncurredCostSheetState();
}

class _IncurredCostSheetState extends State<IncurredCostSheet> {
  final _repository = sl<ItineraryRepository>();
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;

  List<EligiblePlaceEntity> _places = [];
  bool _loadingPlaces = true;
  String? _selectedPlaceId;
  final Set<String> _chargedTo = {};
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.editingCost != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingCost;
    _noteController = TextEditingController(text: editing?.note ?? '');
    _amountController = TextEditingController(
      text: editing != null ? editing.amount.toStringAsFixed(0) : '',
    );
    _selectedPlaceId = editing?.placeId ?? widget.initialPlaceId;
    _chargedTo.addAll(editing?.chargedTo ?? const []);
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _repository.getEligiblePlaces(widget.itineraryId);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loadingPlaces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlaces = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (note.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung/ghi chú');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Vui lòng nhập số tiền hợp lệ');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await _repository.updateIncurredCost(
          widget.itineraryId,
          widget.editingCost!.id,
          note: note,
          amount: amount,
          placeId: _selectedPlaceId,
          chargedTo: _chargedTo.toList(),
        );
      } else {
        await _repository.createIncurredCost(
          widget.itineraryId,
          note: note,
          amount: amount,
          placeId: _selectedPlaceId,
          chargedTo: _chargedTo.toList(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Sửa chi phí phát sinh'
                      : 'Thêm chi phí phát sinh',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung/ghi chú',
                    hintText: 'VD: Gửi xe máy, ăn vặt dọc đường...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền phát sinh (VNĐ)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loadingPlaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPlaceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Địa điểm (tuỳ chọn)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Không gắn địa điểm cụ thể'),
                      ),
                      ..._places.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedPlaceId = value),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Người chi trả (bỏ trống = chia đều cả nhóm)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((member) {
                    final selected = _chargedTo.contains(member.id);
                    return FilterChip(
                      label: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName
                            : 'Thành viên',
                      ),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _chargedTo.add(member.id);
                          } else {
                            _chargedTo.remove(member.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Lưu thay đổi' : 'Thêm chi phí'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
