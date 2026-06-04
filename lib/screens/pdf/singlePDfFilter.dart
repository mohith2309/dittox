import 'package:dittox/model/pdfFile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import '../../providers/ListOfPdfFiles.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

enum PageOrientation {
  landScape,
  potrait;
}

enum PritingSides {
  singleSided,
  doubleSided,
}

enum JobTypes {
  blackAndWhite,
  fullColor,
  partialColor,
}

String getStringPageOrientations(PageOrientation orient) {
  if (orient == PageOrientation.landScape) {
    return "LandScape";
  } else {
    return "Portrait";
  }
}

String getStringPrintingSides(PritingSides side) {
  if (side == PritingSides.singleSided) {
    return "Single Side";
  }
  return "Double Side";
}

String getStringJobType(JobTypes job) {
  if (job == JobTypes.blackAndWhite) {
    return "Black & White";
  } else if (job == JobTypes.fullColor) {
    return "All Color";
  } else {
    return "Partial Color";
  }
}

class SinglePageCustomization extends StatefulWidget {
  final int index;
  const SinglePageCustomization({super.key, required this.index});

  @override
  State<SinglePageCustomization> createState() =>
      _SinglePageCustomizationState();
}

class _SinglePageCustomizationState extends State<SinglePageCustomization> {
  final _pagesRangeController = TextEditingController();
  final _noOfCopies = TextEditingController();
  final _colorPagesController = TextEditingController();
  final _bondPagesController = TextEditingController();
  final _instructionsController = TextEditingController();

  final sheetsSizeList = [
    "A4",
    "A3",
    "A5",
    "Legal",
    "Letter",
    "B5",
    "A6",
    "Post Card",
    "5*7",
    "4*6",
    "35*5",
  ];

  final sheetsBondList = [
    "No Binding",
    "Spiral",
    "Stick File",
    "Staples",
  ];

  bool isInit = true;

  double? contHeight;

  double? sliderContHeight;
  double? totalPrintingContainerHeight;

  double? totalBondPaperContainerHeight;
  double? bondPapersliderContHeight;

  int? totalPages = 0;

  SfRangeValues? values;
  SfRangeValues? colorValues;
  SfRangeValues? bondValues;

  bool boudSheets = false;

  bool showSlider = false;
  bool showwidgetSlider = false;

  String? sheetsSize;
  String? sheetBind;

  PageOrientation pageOri = PageOrientation.potrait;
  PritingSides pagePrint = PritingSides.singleSided;
  JobTypes printjob = JobTypes.blackAndWhite;

  // bool showColorsliderTextbox = false;
  // bool showColorWidgetSliderTextBox = false;
  bool showColorTextBox = false;
  bool showWidgetColorTextBox = false;

  // bool showBondSheetsTextBox = false;
  // bool showBondWingetSheetsTextBox = false;
  // bool showBondSheetsSliderTextBox = false;
  // bool showBondSheetWidgetsliderTextBox = false;

  @override
  void initState() {
    values = SfRangeValues(0, totalPages);
    colorValues = SfRangeValues(0, totalPages);
    bondValues = SfRangeValues(0, totalPages);

    _noOfCopies.text = "1";

    showSlider = false;
    showwidgetSlider = false;

    sheetBind = "No Binding";
    boudSheets = false;

    showColorTextBox = false;
    showWidgetColorTextBox = false;
    // showColorsliderTextbox = false;
    // showColorWidgetSliderTextBox = false;

    sheetsSize = sheetsSizeList[0];

    // showBondSheetsTextBox = false;
    // showBondWingetSheetsTextBox = false;
    // showBondSheetsSliderTextBox = false;
    // showBondSheetWidgetsliderTextBox = false;

    super.initState();
  }

  @override
  void dispose() {
    _pagesRangeController.dispose();
    _noOfCopies.dispose();
    _colorPagesController.dispose();
    _bondPagesController.dispose();
    _instructionsController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (isInit) {
      isInit = false;
      ListOfPDFFiles pdffileList =
          Provider.of<ListOfPDFFiles>(context, listen: false);

      values =
          SfRangeValues(1, pdffileList.allPdfList[widget.index].totalPages);

      totalPages = pdffileList.allPdfList[widget.index].totalPages;

      values = SfRangeValues(1, totalPages);
      colorValues = SfRangeValues(1, totalPages);
      bondValues = SfRangeValues(1, totalPages);

      _pagesRangeController.text = "1-$totalPages";
      _colorPagesController.text = "1-$totalPages";
      _bondPagesController.text = "1-$totalPages";
      _noOfCopies.text = "1";
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

    // contHeight = showSlider ? 140 : 70;

    contHeight = showSlider
        ? calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 290,
            // heightSpecific: true,
          )
        : calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 140,
            // heightSpecific: true,
          );

    // sliderContHeight = showColorTextBox
    //     ? 60 // 70
    //     : 0;

    sliderContHeight = showColorTextBox
        ? calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 120,
            // heightSpecific: true,
          )
        : calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 0,
            // heightSpecific: true,
          );

    // totalPrintingContainerHeight = showColorTextBox ? 130 : 70;

    totalPrintingContainerHeight = showColorTextBox
        ? calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 260,
            // heightSpecific: true,
          )
        : calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 140,
            // heightSpecific: true,
          );

    // bondPapersliderContHeight = showBondSheetsTextBox
    //     ? showBondSheetsSliderTextBox
    //         ? 130 // 140
    //         : 60 // 70
    //     : 0;
    // totalBondPaperContainerHeight = showBondSheetsTextBox
    //     ? showBondSheetsSliderTextBox
    //         ? 190
    //         : 120
    //     : 70;

    ListOfPDFFiles pdffileList =
        Provider.of<ListOfPDFFiles>(context, listen: false);

    return Column(
      children: [
        pdfName(
          pdffileList.allPdfList[widget.index].name,
          pdffileList.allPdfList[widget.index].size,
          pdffileList.allPdfList[widget.index].totalPages,
          context,
          totalScreenHeight,
          totalScreenWidth,
        ),

        //////  <<<<<<<<<<------------- PAGES RANGE SELECT --------------->>>>>>>>>>>>
        pageRange(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<<<<<----------------- NO.OF COPIES -------------------->>>>>>>>>
        noOfCopies(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        //// <<<<<<<<<<<<<   PRINT LAYOUT HERE >>>>>>>>>>>>>>>>>
        printingLayout(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        /// <<<<--------------------    Print Sides ------------ >>>>>
        printingSides(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<<<----------------   SIZE OF PAPERS ------------>>>>>>>>
        sizeOfPages(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<<<---------------     JOB Color -------------->>>>>>>>
        pritingJob(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<< ----------  binding ---------->
        binding(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<< bondStatus ----------->
        bondSheets(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        // <<<<<<< additionalInstructions ------------>
        additionalInstructions(
          pdffileList,
          totalScreenHeight,
          totalScreenWidth,
        ),

        SizedBox(
          // height: 30,
          height: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 130,
            // heightSpecific: true,
          ),
        )
      ],
    );
  }

  DropdownMenuItem<String> buildMenuItem(
    String item,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: TextStyle(
            // fontSize: 20,
            fontSize: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: true,
            ),
            fontWeight: FontWeight.normal,
          ),
        ));
  }

  Widget pdfName(
    String name,
    String size,
    int pagecount,
    BuildContext ctx,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
        margin: EdgeInsets.only(
          // bottom: 15,
          // left: 5,
          // right: 5,
          bottom: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 25,
            // heightSpecific: true,
          ),
          left: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 8,
            // heightSpecific: false,
          ),
          right: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 8,
            // heightSpecific: false,
          ),
        ),
        width: MediaQuery.of(ctx).size.width * 0.95,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              // pdf.pdfName,
              name,
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: ColorPallets.black,
                // fontSize: 24,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: true,
                ),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "$size ($pagecount pages)",
              style: TextStyle(
                  overflow: TextOverflow.fade,
                  color: ColorPallets.black.withValues(alpha: 0.5),
                  // fontSize: 16,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 30,
                    // heightSpecific: true,
                  ),
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic),
            ),
            Divider(
              color: Colors.black,
              thickness: 0.5, // You can adjust the thickness of the divider
              height:
                  // 4,
                  calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
              //// You can adjust the height of the empty space around the divider
            ),
          ],
        ));
  }

  Widget pageRange(
    ListOfPDFFiles pdffileList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Adjust the radius as needed
      ),
      child: Container(
        // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: false,
            )),
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius:
              BorderRadius.circular(8.0), // Adjust the radius as needed
          border: Border.all(
              color: ColorPallets.white, // Set the border color
              // width: 2.0,
              width: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 4,
                // heightSpecific: false,
              )
              // Set the border width
              ),
        ),
        child: AnimatedContainer(
          height: contHeight,
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      // margin: const EdgeInsets.only(left: 5, right: 5),
                      margin: EdgeInsets.only(
                          left: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 10,
                            // heightSpecific: false,
                          ),
                          right: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 10,
                            // heightSpecific: false,
                          )),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            "Pages :",
                            style: TextStyle(
                                // fontSize: 22,
                                fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 40,
                              // heightSpecific: true,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    // width: 10,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 20,
                      // heightSpecific: true,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      // height: 40,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 80,
                        // heightSpecific: true,
                      ),
                      child: TextField(
                        // cursorHeight: 25,
                        cursorHeight: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 50,
                          // heightSpecific: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          setState(() {
                            if (value.trim().isEmpty) {
                              return;
                            }
                            // upade values by _noOfCopies.textß
                            _pagesRangeController.text = value;
                            debugPrint(
                                "PAGERANGE CONTROLLERS ${_pagesRangeController.text}");
                            PdfData oldPdfdata =
                                pdffileList.getPDFFileAtIndex(widget.index);
                            PdfData newPDfData = oldPdfdata.copyWith(
                                pageRange: _pagesRangeController.text);
                            pdffileList.replacePDFAtIndex(
                                widget.index, newPDfData);
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            if (value.trim().isEmpty) {
                              return;
                            }
                            // upade values by _noOfCopies.text
                            _pagesRangeController.text = value;
                            debugPrint(
                                "PAGERANGE CONTROLLERS ${_pagesRangeController.text}");
                            PdfData oldPdfdata =
                                pdffileList.getPDFFileAtIndex(widget.index);
                            PdfData newPDfData = oldPdfdata.copyWith(
                                pageRange: _pagesRangeController.text);
                            pdffileList.replacePDFAtIndex(
                                widget.index, newPDfData);
                          });
                        },
                        controller: _pagesRangeController,
                        decoration: InputDecoration(
                            floatingLabelStyle: TextStyle(
                                // fontSize: 25,
                                fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 50,
                              // heightSpecific: true,
                            )),
                            border: const OutlineInputBorder(),
                            hintStyle: TextStyle(
                                // fontSize: 18,
                                fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 36,
                              // heightSpecific: true,
                            )),
                            hintText: "1-5,8,11-15"),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () async {
                        if (showSlider == false) {
                          setState(() {
                            showSlider = true;
                          });
                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          setState(() {
                            showwidgetSlider = true;
                          });
                        } else {
                          setState(() {
                            showSlider = false;
                            showwidgetSlider = false;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.only(

                            // left: 3,
                            // right: 0,
                            // top: 5,
                            // bottom: 5,

                            left: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 6,
                              // heightSpecific: false,
                            ),
                            right: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 0,
                              // heightSpecific: false,
                            ),
                            top: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 10,
                              // heightSpecific: true,
                            ),
                            bottom: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 10,
                              // heightSpecific: true,
                            )),
                        child: Chip(
                          // decoration: BoxDecoration(
                          //     border: Border.all(color: ColorPallets.deepBlue)),
                          label: Text(
                            "Slider",
                            style: TextStyle(
                                color: Colors.white,
                                // fontSize: 16,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 36,
                                  // heightSpecific: true,
                                )),
                          ),
                          backgroundColor: ColorPallets.deepBlue,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              showwidgetSlider == true &&
                      pdffileList.getPDFFileAtIndex(widget.index).totalPages !=
                          1
                  ? SingleChildScrollView(
                      child: SizedBox(
                        // height: 80,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 160,
                          // heightSpecific: true,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              // width: 10,
                              width: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 20,
                                // heightSpecific: false,
                              ),
                            ),
                            Text(
                              '0',
                              style: TextStyle(
                                // fontSize: 22,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 44,
                                  // heightSpecific: true,
                                ),
                                color: ColorPallets.deepBlue,
                              ),
                            ),
                            Expanded(
                              child: SfRangeSliderTheme(
                                data: const SfRangeSelectorThemeData(
                                    tooltipBackgroundColor:
                                        ColorPallets.deepBlue),
                                child: SfRangeSlider(
                                  activeColor: ColorPallets.deepBlue,
                                  inactiveColor: ColorPallets.lightBlue
                                      .withValues(alpha: 0.3),
                                  min: 1.0,
                                  max: pdffileList
                                      .allPdfList[widget.index].totalPages,
                                  enableTooltip: true,
                                  stepSize: 1,
                                  tooltipShape: const SfPaddleTooltipShape(),
                                  values: values as SfRangeValues,
                                  onChanged: (value) => setState(() {
                                    values = value;
                                    if (values!.start == values!.end) {
                                      String tempString =
                                          values!.start.toInt().toString();
                                      _pagesRangeController.text = tempString;
                                    } else {
                                      String tempString =
                                          "${values!.start.toInt()}-${values!.end.toInt()}";
                                      _pagesRangeController.text = tempString;
                                    }
                                    debugPrint(
                                        "PAGERANGE CONTROLLERS ${_pagesRangeController.text}");
                                    PdfData oldPdfdata = pdffileList
                                        .getPDFFileAtIndex(widget.index);
                                    PdfData newPDfData = oldPdfdata.copyWith(
                                        pageRange: _pagesRangeController.text);
                                    pdffileList.replacePDFAtIndex(
                                        widget.index, newPDfData);
                                  }),
                                ),
                              ),
                            ),
                            Text(
                              totalPages.toString(),
                              style: TextStyle(
                                // fontSize: 22,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 44,
                                  // heightSpecific: true,
                                ),
                                color: ColorPallets.deepBlue,
                              ),
                            ),
                            SizedBox(
                              // width: 10,
                              width: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 20,
                                // heightSpecific: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget noOfCopies(
    ListOfPDFFiles pdffileList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 9,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
              // 8.0,
              calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 8,
            // heightSpecific: true,
          )), // Adjust the radius as needed
          border: Border.all(
              color: ColorPallets.white, // Set the border color
              // width: 2.0,
              width: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 4,
                // heightSpecific: false,
              )
              //// Set the border width
              ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                // margin: const EdgeInsets.only(left: 5, right: 5),
                margin: EdgeInsets.only(
                    left: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 10,
                      // heightSpecific: false,
                    ),
                    right: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 10,
                      // heightSpecific: false,
                    )),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      "no.of copies  :",
                      style: TextStyle(
                          // fontSize: 20,
                          fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      )),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              // width: 10,
              width: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: false,
              ),
            ),
            Expanded(
              flex: 5,
              child: SizedBox(
                // height: 40,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 80,
                  // heightSpecific: true,
                ),
                child: TextField(
                  cursorHeight: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 50,
                    // heightSpecific: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    setState(() {
                      if (value.trim().isEmpty) {
                        return;
                      }
                      // upade values by _noOfCopies.text
                      _noOfCopies.text = value;
                      debugPrint(_noOfCopies.text);
                      PdfData oldPdfdata =
                          pdffileList.getPDFFileAtIndex(widget.index);
                      final copies = int.tryParse(_noOfCopies.text);
                      if (copies == null || copies < 1) return;
                      PdfData newPDfData = oldPdfdata.copyWith(copies: copies);
                      pdffileList.replacePDFAtIndex(widget.index, newPDfData);
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      if (value.trim().isEmpty) {
                        return;
                      }
                      _noOfCopies.text = value;
                      debugPrint(_noOfCopies.text);
                      PdfData oldPdfdata =
                          pdffileList.getPDFFileAtIndex(widget.index);
                      final copies = int.tryParse(_noOfCopies.text);
                      if (copies == null || copies < 1) return;
                      PdfData newPDfData = oldPdfdata.copyWith(copies: copies);
                      pdffileList.replacePDFAtIndex(widget.index, newPDfData);
                    });
                  },

                  // cursorHeight: 25,

                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: _noOfCopies,
                  decoration: InputDecoration(
                      floatingLabelStyle: TextStyle(
                          // fontSize: 25,
                          fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 50,
                        // heightSpecific: true,
                      )),
                      border: const OutlineInputBorder(),
                      hintStyle: TextStyle(
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 36,
                          // heightSpecific: true,
                        ),
                      ),
                      hintText: "1 or 28"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget printingLayout(
    ListOfPDFFiles pdffileList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: Container(
          // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.symmetric(
              vertical: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
              horizontal: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 40,
                // heightSpecific: false,
              )),
          decoration: BoxDecoration(
            color: ColorPallets.white,
            borderRadius: BorderRadius.circular(
                // 8.0,
                calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            )), // Adjust the radius as needed
            border: Border.all(
                color: ColorPallets.white, // Set the border color
                // width: 2.0,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 4,
                  // heightSpecific: false,
                )
                // // Set the border width
                ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  // margin: const EdgeInsets.only(left: 5, right: 5),
                  margin: EdgeInsets.only(
                      left: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 10,
                        // heightSpecific: false,
                      ),
                      right: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 10,
                        // heightSpecific: false,
                      )),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        "Printing Layout  :",
                        style: TextStyle(
                          // fontSize: 20,
                          fontSize: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 40,
                            // heightSpecific: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                // width: 10,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: false,
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                    // 28,
                    calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 56,
                      // heightSpecific: true,
                    ),
                  )),
                  // height: 40,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 80,
                    // heightSpecific: true,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              pageOri = PageOrientation.potrait;

                              // update the value by pageOri or PageOrientations.potrait
                              // to get string of this getStringPageOrientations(pageOri)
                              PdfData oldPdfdata =
                                  pdffileList.getPDFFileAtIndex(widget.index);
                              PdfData newPDfData = oldPdfdata.copyWith(
                                  pdfPrintLayout:
                                      getStringPageOrientations(pageOri));
                              pdffileList.replacePDFAtIndex(
                                  widget.index, newPDfData);
                            });
                          },
                          child: Container(
                            // height: 40,
                            height: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 80,
                              // heightSpecific: true,
                            ),
                            // padding: const EdgeInsets.symmetric(
                            //     horizontal: 5, vertical: 7),
                            padding: EdgeInsets.symmetric(
                                vertical: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 14,
                                  // heightSpecific: true,
                                ),
                                horizontal: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 10,
                                  // heightSpecific: false,
                                )),
                            decoration: BoxDecoration(
                              color: pageOri == PageOrientation.potrait
                                  ? ColorPallets.lightBlue
                                      .withValues(alpha: 0.2)
                                  : null,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                  bottomLeft: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  )),
                              border: Border.all(color: ColorPallets.lightBlue),
                            ),
                            child: const FittedBox(
                              child: Text(
                                " Portrait ",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              pageOri = PageOrientation.landScape;
                              PdfData oldPdfdata =
                                  pdffileList.getPDFFileAtIndex(widget.index);
                              PdfData newPDfData = oldPdfdata.copyWith(
                                  pdfPrintLayout:
                                      getStringPageOrientations(pageOri));
                              pdffileList.replacePDFAtIndex(
                                  widget.index, newPDfData);
                            });
                          },
                          child: Container(
                            // height: 40,
                            height: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 80,
                              // heightSpecific: true,
                            ),
                            // padding: const EdgeInsets.symmetric(
                            //     horizontal: 5, vertical: 7),
                            padding: EdgeInsets.symmetric(
                                vertical: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 14,
                                  // heightSpecific: true,
                                ),
                                horizontal: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 10,
                                  // heightSpecific: false,
                                )),
                            decoration: BoxDecoration(
                              color: pageOri == PageOrientation.landScape
                                  ? ColorPallets.lightBlue
                                      .withValues(alpha: 0.2)
                                  : null,
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                  bottomRight: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  )),
                              border: Border.all(color: ColorPallets.lightBlue),
                            ),
                            child: const FittedBox(
                              child: Text(
                                "LandScape",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // child: Text("fdf")
                ),
              ),
            ],
          )),
    );
  }

  Widget printingSides(
    ListOfPDFFiles pdffileList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: Container(
          // padding: const EdgeInsets.symmetric(
          //   horizontal: 20,
          //   vertical: 10,
          // ),
          padding: EdgeInsets.symmetric(
              vertical: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
              horizontal: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 40,
                // heightSpecific: false,
              )),
          decoration: BoxDecoration(
            color: ColorPallets.white,
            borderRadius: BorderRadius.circular(
              // 8.0,
              calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 16,
                // heightSpecific: true,
              ),
            ), // Adjust the radius as needed
            border: Border.all(
              color: ColorPallets.white, // Set the border color
              // width: 2.0, // Set the border width
              width: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 4,
                // heightSpecific: false,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  margin: EdgeInsets.only(
                    // left: 5,
                    // right: 5,
                    left: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 10,
                      // heightSpecific: false,
                    ),
                    right: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 10,
                      // heightSpecific: false,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Text(
                        "Printing Side :",
                        style: TextStyle(
                          // fontSize: 20,
                          fontSize: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 40,
                            // heightSpecific: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                // width: 10,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: false,
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                    // 28,
                    calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 56,
                      // heightSpecific: true,
                    ),
                  )),
                  // height: 40,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 80,
                    // heightSpecific: true,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              pagePrint = PritingSides.singleSided;

                              // get the string type as getStringPrintingSides(pagePrint)

                              PdfData oldPdfdata =
                                  pdffileList.getPDFFileAtIndex(widget.index);
                              PdfData newPDfData = oldPdfdata.copyWith(
                                  pdfSides: getStringPrintingSides(pagePrint));
                              pdffileList.replacePDFAtIndex(
                                  widget.index, newPDfData);
                            });
                          },
                          child: Container(
                            // height: 40,
                            height: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 80,
                              // heightSpecific: true,
                            ),
                            // padding: const EdgeInsets.symmetric(
                            //     horizontal: 10, vertical: 7),
                            padding: EdgeInsets.symmetric(
                                vertical: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 14,
                                  // heightSpecific: true,
                                ),
                                horizontal: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 20,
                                  // heightSpecific: false,
                                )),
                            decoration: BoxDecoration(
                              color: pagePrint == PritingSides.singleSided
                                  ? ColorPallets.lightBlue
                                      .withValues(alpha: 0.2)
                                  : null,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                  // 22,
                                  calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 44,
                                    // heightSpecific: true,
                                  ),
                                ),
                                bottomLeft: Radius.circular(
                                  // 22,
                                  calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 44,
                                    // heightSpecific: true,
                                  ),
                                ),
                              ),
                              border: Border.all(color: ColorPallets.lightBlue),
                            ),
                            child: const FittedBox(
                              child: Text(
                                "Single side",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              pagePrint = PritingSides.doubleSided;
                              // get the string type as getStringPrintingSides(pagePrint)

                              PdfData oldPdfdata =
                                  pdffileList.getPDFFileAtIndex(widget.index);
                              PdfData newPDfData = oldPdfdata.copyWith(
                                  pdfSides: getStringPrintingSides(pagePrint));
                              pdffileList.replacePDFAtIndex(
                                  widget.index, newPDfData);
                            });
                          },
                          child: Container(
                            // height: 40,
                            // padding: const EdgeInsets.symmetric(
                            //     horizontal: 5, vertical: 7),
                            height: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 80,
                              // heightSpecific: true,
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 14,
                                  // heightSpecific: true,
                                ),
                                horizontal: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 10,
                                  // heightSpecific: false,
                                )),
                            decoration: BoxDecoration(
                              color: pagePrint == PritingSides.doubleSided
                                  ? ColorPallets.lightBlue
                                      .withValues(alpha: 0.2)
                                  : null,
                              borderRadius: BorderRadius.only(
                                // topRight: Radius.circular(22),
                                // bottomRight: Radius.circular(22),
                                topRight: Radius.circular(
                                  // 22,
                                  calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 44,
                                    // heightSpecific: true,
                                  ),
                                ),
                                bottomRight: Radius.circular(
                                  // 22,
                                  calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 44,
                                    // heightSpecific: true,
                                  ),
                                ),
                              ),
                              border: Border.all(color: ColorPallets.lightBlue),
                            ),
                            child: const FittedBox(
                              child: Text(
                                "double side",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // child: Text("fdf")
                ),
              ),
            ],
          )),
    );
  }

  Widget sizeOfPages(
    ListOfPDFFiles pdffileList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: Container(
        height: 70,
        // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
            // 8.0,
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            ),
          ), // Adjust the radius as needed
          border: Border.all(
            color: ColorPallets.white, // Set the border color
            // width: 2.0, // Set the border width
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 4,
              // heightSpecific: false,
            ),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(
            flex: 4,
            child: Container(
              // margin: const EdgeInsets.only(right: 5, left: 5),
              margin: EdgeInsets.only(
                  right: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 10,
                    // heightSpecific: false,
                  ),
                  left: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 10,
                    // heightSpecific: false,
                  )),
              child: Center(
                child: FittedBox(
                  child: Text(
                    "Size of pages :",
                    style: TextStyle(
                      // fontSize: 20,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            // width: 10,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: false,
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              // height: 40,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 80,
                // heightSpecific: true,
              ),
              padding: EdgeInsets.only(
                // left: 40,
                left: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 80,
                  // heightSpecific: false,
                ),
                // top: 2,
                top: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 4,
                  // heightSpecific: true,
                ),
                // bottom: 2,
                bottom: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 4,
                  // heightSpecific: true,
                ),
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    // 12,
                    calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 12,
                      // heightSpecific: true,
                    ),
                  ),
                  border: Border.all(
                    color: ColorPallets.lightBlue,
                    // width: 1,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 2,
                      // heightSpecific: false,
                    ),
                  )),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: sheetsSize,
                items: sheetsSizeList
                    .map((e) => buildMenuItem(
                          e,
                          totalScreenHeight,
                          totalScreenWidth,
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  sheetsSize = value;

                  // update the value as value.toString()

                  PdfData oldPdfdata =
                      pdffileList.getPDFFileAtIndex(widget.index);
                  PdfData newPDfData =
                      oldPdfdata.copyWith(paperSize: value.toString());
                  pdffileList.replacePDFAtIndex(widget.index, newPDfData);
                }),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  Widget pritingJob(
    ListOfPDFFiles pdffilesList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: totalPrintingContainerHeight,
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
            // 8.0,
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            ),
          ), // Adjust the radius as needed
          border: Border.all(
            color: ColorPallets.white, // Set the border color
            width: 4.0, // Set the border width
          ),
        ),
        // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    // margin: const EdgeInsets.only(left: 5, right: 5),
                    margin: EdgeInsets.only(
                        left: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: false,
                        ),
                        right: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: false,
                        )),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "Printing Job :",
                          style: TextStyle(
                            // fontSize: 20,
                            fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 40,
                              // heightSpecific: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  // width: 10,
                  width: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                      // 28,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 56,
                        // heightSpecific: true,
                      ),
                    )),
                    // height: 40,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 80,
                      // heightSpecific: true,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                printjob = JobTypes.blackAndWhite;
                                showColorTextBox = false;
                                showWidgetColorTextBox = false;
                                // showColorsliderTextbox = false;
                                // showColorWidgetSliderTextBox = false;

                                // update the values as getStringJobType(prinyjob) JobTypes.blackAndWhite
                                PdfData oldPdfdata = pdffilesList
                                    .getPDFFileAtIndex(widget.index);
                                PdfData newPDfData = oldPdfdata.copyWith(
                                    color: getStringJobType(printjob));
                                pdffilesList.replacePDFAtIndex(
                                    widget.index, newPDfData);
                              });
                            },
                            child: Container(
                              // height: 40,
                              height: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 80,
                                // heightSpecific: false,
                              ),
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 8, vertical: 7),
                              padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 14,
                                    // heightSpecific: true,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 16,
                                    // heightSpecific: false,
                                  )),
                              decoration: BoxDecoration(
                                color: printjob == JobTypes.blackAndWhite
                                    ? ColorPallets.lightBlue
                                        .withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    ),
                                    bottomLeft: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    )),
                                border:
                                    Border.all(color: ColorPallets.lightBlue),
                              ),
                              child: const FittedBox(
                                child: Text("B&W"),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                printjob = JobTypes.fullColor;
                                showColorTextBox = false;
                                showWidgetColorTextBox = false;
                                // showColorsliderTextbox = false;
                                // showColorWidgetSliderTextBox = false;

                                // update the values as getStringJobType(prinyjob) // JobTypes.fullColor

                                PdfData oldPdfdata = pdffilesList
                                    .getPDFFileAtIndex(widget.index);
                                PdfData newPDfData = oldPdfdata.copyWith(
                                    color: getStringJobType(printjob));
                                pdffilesList.replacePDFAtIndex(
                                    widget.index, newPDfData);
                              });
                            },
                            child: Container(
                              // height: 40,
                              height: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 80,
                                // heightSpecific: true,
                              ),
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 7, vertical: 7),
                              padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 14,
                                    // heightSpecific: true,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 14,
                                    // heightSpecific: false,
                                  )),
                              decoration: BoxDecoration(
                                color: printjob == JobTypes.fullColor
                                    ? ColorPallets.lightBlue
                                        .withValues(alpha: 0.2)
                                    : null,
                                // borderRadius: const BorderRadius.only(
                                //     topRight: Radius.circular(22),
                                //     bottomRight: Radius.circular(22)),
                                border:
                                    Border.all(color: ColorPallets.lightBlue),
                              ),
                              child: const FittedBox(
                                child: Text("Color"),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                printjob = JobTypes.partialColor;

                                PdfData oldPdfdata = pdffilesList
                                    .getPDFFileAtIndex(widget.index);
                                PdfData newPDfData = oldPdfdata.copyWith(
                                    color: getStringJobType(printjob));
                                pdffilesList.replacePDFAtIndex(
                                    widget.index, newPDfData);
                              });
                              if (showColorTextBox == false) {
                                setState(() {
                                  showColorTextBox = true;
                                });
                                await Future.delayed(
                                    const Duration(milliseconds: 300));
                                setState(() {
                                  showWidgetColorTextBox = true;
                                });
                              } else {
                                setState(() {
                                  showColorTextBox = false;
                                  showWidgetColorTextBox = false;
                                });
                              }
                            },
                            child: Container(
                              // height: 40,
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 3, vertical: 7),
                              height: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 80,
                                // heightSpecific: true,
                              ),
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 7, vertical: 7),
                              padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 14,
                                    // heightSpecific: true,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 6,
                                    // heightSpecific: false,
                                  )),
                              decoration: BoxDecoration(
                                color: printjob == JobTypes.partialColor
                                    ? ColorPallets.lightBlue
                                        .withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.only(
                                  // topRight: Radius.circular(22),
                                  // bottomRight: Radius.circular(22),
                                  topRight: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                  bottomRight: Radius.circular(
                                    // 22,
                                    calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 44,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                ),
                                border:
                                    Border.all(color: ColorPallets.lightBlue),
                              ),
                              child: const FittedBox(
                                child: Text("ColPar"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // child: Text("fdf")
                  ),
                ),
              ],
            ),
            showWidgetColorTextBox == true
                ? AnimatedContainer(
                    padding: EdgeInsets.only(
                      // top: 20,
                      top: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                    height: sliderContHeight,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                margin: EdgeInsets.only(
                                  // left: 5,
                                  // right: 5,
                                  left: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 10,
                                    // heightSpecific: false,
                                  ),
                                  right: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 10,
                                    // heightSpecific: false,
                                  ),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    child: Text(
                                      "Color Pages :",
                                      style: TextStyle(
                                        // fontSize: 20,
                                        fontSize: calculateDynamicFontSize(
                                          totalScreenHeight: totalScreenHeight,
                                          totalScreenWidth: totalScreenWidth,
                                          currentFontSize: 40,
                                          // heightSpecific: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              // width: 10,
                              width: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 20,
                                // heightSpecific: true,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                // height: 40,
                                height: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 80,
                                  // heightSpecific: true,
                                ),
                                padding: const EdgeInsets.all(0),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.trim().isEmpty) {
                                        return;
                                      }
                                      // upade values by _noOfCopies.textß
                                      _colorPagesController.text = value;
                                      debugPrint(
                                          "COLOR PAGERANGE CONTROLLERS ${_colorPagesController.text}");
                                      PdfData oldPdfdata = pdffilesList
                                          .getPDFFileAtIndex(widget.index);
                                      PdfData newPDfData = oldPdfdata.copyWith(
                                        color: getStringJobType(
                                            JobTypes.partialColor),
                                        colorParPageNumbers:
                                            _colorPagesController.text,
                                      );
                                      pdffilesList.replacePDFAtIndex(
                                          widget.index, newPDfData);
                                    });
                                  },
                                  onSubmitted: (value) {
                                    setState(() {
                                      // update the values with _colorPagesController.text and getStringjobtype(JobTypes.partialColor);
                                      if (value.trim().isEmpty) {
                                        return;
                                      }
                                      // upade values by _noOfCopies.textß
                                      _colorPagesController.text = value;
                                      debugPrint(
                                          "COLOR PAGERANGE CONTROLLERS ${_colorPagesController.text}");
                                      PdfData oldPdfdata = pdffilesList
                                          .getPDFFileAtIndex(widget.index);
                                      PdfData newPDfData = oldPdfdata.copyWith(
                                        color: getStringJobType(
                                            JobTypes.partialColor),
                                        colorParPageNumbers:
                                            _colorPagesController.text,
                                      );
                                      pdffilesList.replacePDFAtIndex(
                                          widget.index, newPDfData);
                                    });
                                  },
                                  controller: _colorPagesController,
                                  // cursorHeight: 25,
                                  cursorHeight: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 50,
                                    // heightSpecific: true,
                                  ),
                                  decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintStyle: TextStyle(
                                        // fontSize: 18,
                                        fontSize: calculateDynamicFontSize(
                                          totalScreenHeight: totalScreenHeight,
                                          totalScreenWidth: totalScreenWidth,
                                          currentFontSize: 36,
                                          // heightSpecific: true,
                                        ),
                                      ),
                                      hintText: "1,2,4,5,8"),
                                ),
                              ),
                            ),
                            SizedBox(
                              // width: 10,
                              width: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 20,
                                // heightSpecific: true,
                              ),
                            ),
                            // Expanded(
                            //   flex: 2,
                            //   child: InkWell(
                            //     onTap: () async {
                            //       if (showColorsliderTextbox == false) {
                            //         setState(() {
                            //           showColorsliderTextbox = true;
                            //         });
                            //         await Future.delayed(
                            //             const Duration(milliseconds: 300));
                            //         setState(() {
                            //           showColorWidgetSliderTextBox = true;
                            //         });
                            //       } else {
                            //         setState(() {
                            //           showColorsliderTextbox = false;
                            //           showColorWidgetSliderTextBox = false;
                            //         });
                            //       }
                            //     },
                            //     child: Container(
                            //       // padding: EdgeInsets.only(
                            //       //   left: 10,
                            //       // ),
                            //       child: const Chip(
                            //         label: FittedBox(
                            //           fit: BoxFit.contain,
                            //           child: Text(
                            //             "Slider",
                            //             style: TextStyle(
                            //                 color: Colors.white, fontSize: 16),
                            //           ),
                            //         ),
                            //         backgroundColor: ColorPallets.deepBlue,
                            //       ),
                            //     ),
                            //   ),
                            // )
                          ],
                        ),
                        // showColorWidgetSliderTextBox == true
                        //     ? SingleChildScrollView(
                        //         child: SizedBox(
                        //           height: 70,
                        //           child: Row(
                        //             mainAxisAlignment:
                        //                 MainAxisAlignment.spaceEvenly,
                        //             children: [
                        //               const SizedBox(
                        //                 width: 10,
                        //               ),
                        //               const Text(
                        //                 '0',
                        //                 style: TextStyle(
                        //                     fontSize: 22,
                        //                     color: ColorPallets.deepBlue),
                        //               ),
                        //               Expanded(
                        //                 child: SfRangeSliderTheme(
                        //                   data: SfRangeSelectorThemeData(
                        //                     tooltipBackgroundColor:
                        //                         ColorPallets.deepBlue,
                        //                   ),
                        //                   child: SfRangeSlider(
                        //                       activeColor:
                        //                           ColorPallets.deepBlue,
                        //                       inactiveColor: ColorPallets
                        //                           .lightBlue
                        //                           .withOpacity(.3),
                        //                       key: const ValueKey(
                        //                           "colorpagesClider"),
                        //                       min: 1,
                        //                       max: totalPages!.toDouble(),
                        //                       enableTooltip: true,
                        //                       stepSize: 1,
                        //                       tooltipShape:
                        //                           const SfPaddleTooltipShape(),
                        //                       values:
                        //                           colorValues as SfRangeValues,
                        //                       onChanged: (value) {
                        //                         setState(() {
                        //                           colorValues = value;
                        //                           if (colorValues!.start ==
                        //                               colorValues!.end) {
                        //                             String tempString =
                        //                                 "${colorValues!.start.toInt()}";
                        //                             _colorPagesController.text =
                        //                                 tempString;
                        //                           } else {
                        //                             String tempString =
                        //                                 "${colorValues!.start.toInt()}-${colorValues!.end.toInt()}";
                        //                             _colorPagesController.text =
                        //                                 tempString;
                        //                           }

                        //                           PdfData oldPdfdata =
                        //                               pdffilesList
                        //                                   .getPDFFileAtIndex(
                        //                                       widget.index);
                        //                           PdfData newPDfData = PdfData(
                        //                               name: oldPdfdata.name,
                        //                               size: oldPdfdata.size,
                        //                               totalPages:
                        //                                   oldPdfdata.totalPages,
                        //                               bondPages:
                        //                                   oldPdfdata.bondPages,
                        //                               copies: oldPdfdata.copies,
                        //                               binding:
                        //                                   oldPdfdata.binding,
                        //                               paperSize:
                        //                                   oldPdfdata.paperSize,
                        //                               pdfSides:
                        //                                   oldPdfdata.pdfSides,
                        //                               pdfPrintLayout: oldPdfdata
                        //                                   .pdfPrintLayout,
                        //                               color: getStringJobType(
                        //                                   JobTypes
                        //                                       .partialColor),
                        //                               pageRange:
                        //                                   oldPdfdata.pageRange,
                        //                               colorParDesciption:
                        //                                   oldPdfdata
                        //                                       .colorParDesciption,
                        //                               colorParPageNumbers:
                        //                                   _colorPagesController
                        //                                       .text,
                        //                               colorParTotal: oldPdfdata
                        //                                   .colorParTotal,
                        //                               additionDesciption:
                        //                                   oldPdfdata
                        //                                       .additionDesciption,
                        //                               uploadID:
                        //                                   oldPdfdata.uploadID);
                        //                           pdffilesList
                        //                               .replacePDFAtIndex(
                        //                                   widget.index,
                        //                                   newPDfData);
                        //                           pdffilesList.printPDFFile();
                        //                         });
                        //                       }),
                        //                 ),
                        //               ),
                        //               Text(
                        //                 totalPages.toString(),
                        //                 style: const TextStyle(
                        //                     fontSize: 22,
                        //                     color: ColorPallets.deepBlue),
                        //               ),
                        //               const SizedBox(
                        //                 width: 10,
                        //               )
                        //             ],
                        //           ),
                        //         ),
                        //       )
                        //     : SizedBox(),
                      ],
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  Widget binding(
    ListOfPDFFiles pdffilesList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
            // 8.0,
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            ),
          ), // Adjust the radius as needed
          border: Border.all(
            color: ColorPallets.white, // Set the border color
            // width: 2.0, // Set the border width
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 4,
              // heightSpecific: false,
            ),
          ),
        ),
        // height: 60,
        height: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 120,
          // heightSpecific: true,
        ),
        // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: EdgeInsets.only(
                // left: 5,
                // right: 5,
                left: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 10,
                  // heightSpecific: false,
                ),
                right: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: false,
                ),
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    "Binding :",
                    style: TextStyle(
                      // fontSize: 20,
                      fontSize: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            // width: 10,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: false,
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              height: 80,
              padding: EdgeInsets.only(
                // left: 20,
                // top: 2,
                // bottom: 2,
                top: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 4,
                  // heightSpecific: true,
                ),
                bottom: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 4,
                  // heightSpecific: true,
                ),
                left: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: false,
                ),
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    // 12,
                    calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 24,
                      // heightSpecific: true,
                    ),
                  ),
                  border: Border.all(
                    color: ColorPallets.lightBlue,
                    // width: 1,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 2,
                      // heightSpecific: false,
                    ),
                  )),
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: sheetBind,
                items: sheetsBondList
                    .map((e) => buildMenuItem(
                          e,
                          totalScreenHeight,
                          totalScreenWidth,
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  sheetBind = value;
                  // update values by  value.toString(),
                  debugPrint("PRESSED !!!`");
                  PdfData oldPdfdata =
                      pdffilesList.getPDFFileAtIndex(widget.index);
                  PdfData newPDfData =
                      oldPdfdata.copyWith(binding: value.toString());
                  pdffilesList.replacePDFAtIndex(widget.index, newPDfData);
                }),
              )),
            ),
          ),
          // const SizedBox(width: 20),
        ]),
      ),
    );
  }

  Widget bondSheets(
    ListOfPDFFiles pdffilesList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          8.0,
          // calculateDynamicFontSize(
          //   totalScreenHeight: totalScreenHeight,
          //   totalScreenWidth: totalScreenWidth,
          //   currentFontSize: 8,
          //   // heightSpecific: true,
          // ),
        ), // Adjust the radius as needed
      ),
      child: AnimatedContainer(
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
            // 8.0,
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            ),
          ), // Adjust the radius as needed
          border: Border.all(
            color: ColorPallets.white, // Set the border color
            // width: 2.0, // Set the border width
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 4,
              // heightSpecific: false,
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        height: totalBondPaperContainerHeight,
        // padding: const EdgeInsets.only(
        //   left: 20,
        //   right: 20,
        //   top: 13,
        //   bottom: 13,
        // ),
        padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 26,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 40,
            // heightSpecific: false,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    // margin: const EdgeInsets.only(left: 5, right: 5),
                    margin: EdgeInsets.symmetric(
                        vertical: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 0,
                          // heightSpecific: true,
                        ),
                        horizontal: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: false,
                        )),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "BondPaper :",
                          style: TextStyle(
                            // fontSize: 20,
                            fontSize: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 40,
                              // heightSpecific: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  // width: 10,
                  width: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 20,
                    // heightSpecific: false,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                      // 28,
                      calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 56,
                        // heightSpecific: true,
                      ),
                    )),

                    // height: 40,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 80,
                      // heightSpecific: true,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                boudSheets = false;
                                PdfData oldPdfdata = pdffilesList
                                    .getPDFFileAtIndex(widget.index);
                                PdfData newPDfData =
                                    oldPdfdata.copyWith(bondPages: false);
                                pdffilesList.replacePDFAtIndex(
                                    widget.index, newPDfData);

                                // showBondSheetsTextBox = false;
                                // showBondWingetSheetsTextBox = false;
                                // showBondSheetsSliderTextBox = false;
                                // showBondSheetWidgetsliderTextBox = false;

                                // update isBondpaper as false
                                // currentPdfModal = PdfFiltersModal(
                                //     pagesRange: currentPdfModal!.pagesRange,
                                //     noOfCopies: currentPdfModal!.noOfCopies,
                                //     pageOrient: currentPdfModal!.pageOrient,
                                //     pagePrintSide:
                                //         currentPdfModal!.pagePrintSide,
                                //     pageSize: currentPdfModal!.pageSize,
                                //     printJobType: currentPdfModal!.printJobType,
                                //     colorPagesRange:
                                //         currentPdfModal!.colorPagesRange,
                                //     bindingType: currentPdfModal!.bindingType,
                                //     isBondPaperNeeded: false,
                                //     bondPaperRange: "",
                                //     isTransparentSheetNeed:
                                //         currentPdfModal!.isTransparentSheetNeed,
                                //     transparentSheetColor:
                                //         currentPdfModal!.transparentSheetColor,
                                //     seletedShop: currentPdfModal!.seletedShop);
                                // totalPrice = currentPdfModal!.getCostOfXerox();
                              });
                            },
                            child: Container(
                              // height: 40,
                              height: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 80,
                                // heightSpecific: true,
                              ),
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: boudSheets == false
                                    ? ColorPallets.lightBlue
                                        .withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    ),
                                    bottomLeft: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    )),
                                border:
                                    Border.all(color: ColorPallets.lightBlue),
                              ),
                              child: Center(
                                child: Text(
                                  "No",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    // fontSize: 20,
                                    fontSize: calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 40,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                boudSheets = true;
                                PdfData oldPdfdata = pdffilesList
                                    .getPDFFileAtIndex(widget.index);
                                PdfData newPDfData =
                                    oldPdfdata.copyWith(bondPages: true);
                                pdffilesList.replacePDFAtIndex(
                                    widget.index, newPDfData);
                              });
                              // update isbondpaper is true
                              // currentPdfModal = PdfFiltersModal(
                              //     pagesRange: currentPdfModal!.pagesRange,
                              //     noOfCopies: currentPdfModal!.noOfCopies,
                              //     pageOrient: currentPdfModal!.pageOrient,
                              //     pagePrintSide: currentPdfModal!.pagePrintSide,
                              //     pageSize: currentPdfModal!.pageSize,
                              //     printJobType: currentPdfModal!.printJobType,
                              //     colorPagesRange:
                              //         currentPdfModal!.colorPagesRange,
                              //     bindingType: currentPdfModal!.bindingType,
                              //     isBondPaperNeeded: true,
                              //     bondPaperRange: _bondPagesController.text,
                              //     isTransparentSheetNeed:
                              //         currentPdfModal!.isTransparentSheetNeed,
                              //     transparentSheetColor:
                              //         currentPdfModal!.transparentSheetColor,
                              //     seletedShop: currentPdfModal!.seletedShop);
                              // totalPrice = currentPdfModal!.getCostOfXerox();
                              // if (showBondSheetsTextBox == false) {
                              //   setState(() {
                              //     showBondSheetsTextBox = true;
                              //   });
                              //   await Future.delayed(
                              //       const Duration(milliseconds: 300));
                              //   setState(() {
                              //     showBondWingetSheetsTextBox = true;
                              //   });
                              // } else {
                              //   setState(() {
                              //     showBondSheetsTextBox = false;
                              //     showBondWingetSheetsTextBox = false;
                              //   });
                              // }
                            },
                            child: Container(
                              // height: 40,
                              height: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 80,
                                // heightSpecific: true,
                              ),
                              // padding: const EdgeInsets.symmetric(
                              //     horizontal: 5, vertical: 10),
                              padding: EdgeInsets.symmetric(
                                  vertical: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 20,
                                    // heightSpecific: true,
                                  ),
                                  horizontal: calculateDynamicFontSize(
                                    totalScreenHeight: totalScreenHeight,
                                    totalScreenWidth: totalScreenWidth,
                                    currentFontSize: 10,
                                    // heightSpecific: false,
                                  )),
                              decoration: BoxDecoration(
                                color: boudSheets == true
                                    ? ColorPallets.lightBlue
                                        .withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    ),
                                    bottomRight: Radius.circular(
                                      // 22,
                                      calculateDynamicFontSize(
                                        totalScreenHeight: totalScreenHeight,
                                        totalScreenWidth: totalScreenWidth,
                                        currentFontSize: 44,
                                        // heightSpecific: true,
                                      ),
                                    )),
                                border:
                                    Border.all(color: ColorPallets.lightBlue),
                              ),
                              child: Center(
                                child: Text(
                                  "Yes",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    // fontSize: 20,
                                    fontSize: calculateDynamicFontSize(
                                      totalScreenHeight: totalScreenHeight,
                                      totalScreenWidth: totalScreenWidth,
                                      currentFontSize: 40,
                                      // heightSpecific: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // child: Text("fdf")
                  ),
                ),
              ],
            ),
            // showBondWingetSheetsTextBox == true
            //     ? AnimatedContainer(
            //         padding: const EdgeInsets.only(top: 7),
            //         height: bondPapersliderContHeight,
            //         duration: const Duration(milliseconds: 300),
            //         child: Column(
            //           children: [
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //               children: [
            //                 Expanded(
            //                   flex: 3,
            //                   child: Container(
            //                     margin:
            //                         const EdgeInsets.only(left: 5, right: 5),
            //                     child: const Center(
            //                       child: FittedBox(
            //                         child: Text(
            //                           "Bond Pages :",
            //                           style: TextStyle(fontSize: 20),
            //                         ),
            //                       ),
            //                     ),
            //                   ),
            //                 ),
            //                 const SizedBox(
            //                   width: 10,
            //                 ),
            //                 Expanded(
            //                   flex: 3,
            //                   child: Container(
            //                     height: 40,
            //                     padding: const EdgeInsets.all(0),
            //                     child: TextField(
            //                       onSubmitted: (value) {
            //                         setState(() {
            //                           // update isBondpaper true , bondpaperrange is _bondPagesController.text,

            //                           // currentPdfModal = PdfFiltersModal(
            //                           //     pagesRange:
            //                           //         currentPdfModal!.pagesRange,
            //                           //     noOfCopies:
            //                           //         currentPdfModal!.noOfCopies,
            //                           //     pageOrient:
            //                           //         currentPdfModal!.pageOrient,
            //                           //     pagePrintSide:
            //                           //         currentPdfModal!.pagePrintSide,
            //                           //     pageSize: currentPdfModal!.pageSize,
            //                           //     printJobType:
            //                           //         currentPdfModal!.printJobType,
            //                           //     colorPagesRange:
            //                           //         _colorPagesController.text,
            //                           //     bindingType:
            //                           //         currentPdfModal!.bindingType,
            //                           //     isBondPaperNeeded: true,
            //                           //     bondPaperRange:
            //                           //         _bondPagesController.text,
            //                           //     isTransparentSheetNeed:
            //                           //         currentPdfModal!
            //                           //             .isTransparentSheetNeed,
            //                           //     transparentSheetColor:
            //                           //         currentPdfModal!
            //                           //             .transparentSheetColor,
            //                           //     seletedShop:
            //                           //         currentPdfModal!.seletedShop);
            //                           // totalPrice =
            //                           //     currentPdfModal!.getCostOfXerox();
            //                         });
            //                       },
            //                       cursorHeight: 25,
            //                       controller: _bondPagesController,
            //                       decoration: const InputDecoration(
            //                           border: OutlineInputBorder(),
            //                           hintStyle: TextStyle(fontSize: 18),
            //                           hintText: "1-5,8"),
            //                     ),
            //                   ),
            //                 ),
            //                 const SizedBox(
            //                   width: 10,
            //                 ),
            //                 Expanded(
            //                   flex: 2,
            //                   child: InkWell(
            //                     onTap: () async {
            //                       if (showBondSheetsSliderTextBox == false) {
            //                         setState(() {
            //                           showBondSheetsSliderTextBox = true;
            //                         });
            //                         await Future.delayed(
            //                             const Duration(milliseconds: 300));
            //                         setState(() {
            //                           showBondSheetWidgetsliderTextBox = true;
            //                         });
            //                       } else {
            //                         setState(() {
            //                           showBondSheetsSliderTextBox = false;
            //                           showBondSheetWidgetsliderTextBox = false;
            //                         });
            //                       }
            //                     },
            //                     child: Container(
            //                       // padding: EdgeInsets.symmetric(
            //                       //     horizontal: 10, vertical: 5),
            //                       child: const Chip(
            //                         label: FittedBox(
            //                           fit: BoxFit.contain,
            //                           child: Text(
            //                             "Slider",
            //                             style: TextStyle(
            //                                 color: Colors.white, fontSize: 16),
            //                           ),
            //                         ),
            //                         backgroundColor: ColorPallets.deepBlue,
            //                       ),
            //                     ),
            //                   ),
            //                 )
            //               ],
            //             ),
            //             showBondSheetWidgetsliderTextBox == true
            //                 ? SingleChildScrollView(
            //                     child: SizedBox(
            //                       height: 70,
            //                       child: Row(
            //                         mainAxisAlignment:
            //                             MainAxisAlignment.spaceEvenly,
            //                         children: [
            //                           const SizedBox(
            //                             width: 10,
            //                           ),
            //                           const Text(
            //                             '0',
            //                             style: TextStyle(
            //                                 fontSize: 22,
            //                                 color: ColorPallets.deepBlue),
            //                           ),
            //                           Expanded(
            //                             child: SfRangeSliderTheme(
            //                               data: SfRangeSelectorThemeData(
            //                                   tooltipBackgroundColor:
            //                                       ColorPallets.deepBlue),
            //                               child: SfRangeSlider(
            //                                 activeColor: ColorPallets.deepBlue,
            //                                 inactiveColor: ColorPallets
            //                                     .lightBlue
            //                                     .withOpacity(.3),
            //                                 min: 1,
            //                                 max: totalPages!.toDouble(),
            //                                 enableTooltip: true,
            //                                 stepSize: 1,
            //                                 tooltipShape:
            //                                     const SfPaddleTooltipShape(),
            //                                 values: bondValues as SfRangeValues,
            //                                 onChanged: (value) {
            //                                   setState(
            //                                     () {
            //                                       bondValues = value;
            //                                       if (bondValues!.start ==
            //                                           bondValues!.end) {
            //                                         String tempString =
            //                                             "${bondValues!.start.toInt()}";
            //                                         _bondPagesController.text =
            //                                             tempString;
            //                                       } else {
            //                                         String tempString =
            //                                             "${bondValues!.start.toInt()}-${bondValues!.end.toInt()}";
            //                                         _bondPagesController.text =
            //                                             tempString;
            //                                       }
            //                                     },
            //                                   );
            //                                   setState(() {
            //                                     // is bondpaper is true , bondpaperrange is _bondPagesController.text
            //                                     // currentPdfModal = PdfFiltersModal(
            //                                     //     pagesRange: currentPdfModal!
            //                                     //         .pagesRange,
            //                                     //     noOfCopies: currentPdfModal!
            //                                     //         .noOfCopies,
            //                                     //     pageOrient: currentPdfModal!
            //                                     //         .pageOrient,
            //                                     //     pagePrintSide: currentPdfModal!
            //                                     //         .pagePrintSide,
            //                                     //     pageSize: currentPdfModal!
            //                                     //         .pageSize,
            //                                     //     printJobType:
            //                                     //         currentPdfModal!
            //                                     //             .printJobType,
            //                                     //     colorPagesRange:
            //                                     //         currentPdfModal!
            //                                     //             .colorPagesRange,
            //                                     //     bindingType:
            //                                     //         currentPdfModal!
            //                                     //             .bindingType,
            //                                     //     isBondPaperNeeded: true,
            //                                     //     bondPaperRange:
            //                                     //         _bondPagesController
            //                                     //             .text,
            //                                     //     isTransparentSheetNeed:
            //                                     //         currentPdfModal!
            //                                     //             .isTransparentSheetNeed,
            //                                     //     transparentSheetColor:
            //                                     //         currentPdfModal!
            //                                     //             .transparentSheetColor,
            //                                     //     seletedShop:
            //                                     //         currentPdfModal!
            //                                     //             .seletedShop);
            //                                     // totalPrice = currentPdfModal!
            //                                     //     .getCostOfXerox();
            //                                   });
            //                                 },
            //                               ),
            //                             ),
            //                           ),
            //                           Text(
            //                             totalPages.toString(),
            //                             style: const TextStyle(
            //                                 fontSize: 22,
            //                                 color: ColorPallets.deepBlue),
            //                           ),
            //                           const SizedBox(
            //                             width: 10,
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   )
            //                 : SizedBox(),
            //           ],
            //         ),
            //       )
            //     : SizedBox()
          ],
        ),
      ),
    );
  }

  Widget additionalInstructions(
    ListOfPDFFiles pdffilesList,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Card(
      elevation: 3,
      shadowColor: ColorPallets.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8
            // calculateDynamicFontSize(
            //   totalScreenHeight: totalScreenHeight,
            //   totalScreenWidth: totalScreenWidth,
            //   currentFontSize: 8,
            //   // heightSpecific: true,
            // ),
            ), // Adjust the radius as needed
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorPallets.white,
          borderRadius: BorderRadius.circular(
            // 8.0,
            calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 16,
              // heightSpecific: true,
            ),
          ), // Adjust the radius as needed
          border: Border.all(
            color: ColorPallets.white, // Set the border color
            // width: 2.0, // Set the border width
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 4,
              // heightSpecific: false,
            ),
          ),
        ),
        // height: 60,
        // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: Text(
                'Additional Instructions',
                style: TextStyle(
                  // fontSize: 20,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  // fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              // height: 8,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 16,
                // heightSpecific: true,
              ),
            ),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter additional instructions...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.trim().isEmpty) {
                    return;
                  }
                  _instructionsController.text = value;
                  PdfData oldPdfdata =
                      pdffilesList.getPDFFileAtIndex(widget.index);
                  PdfData newPDfData = oldPdfdata.copyWith(
                      additionDesciption: _instructionsController.text);
                  pdffilesList.replacePDFAtIndex(widget.index, newPDfData);
                });
              },
              onSubmitted: (value) {
                setState(() {
                  // update the valye here
                  if (value.trim().isEmpty) {
                    return;
                  }
                  _instructionsController.text = value;
                  PdfData oldPdfdata =
                      pdffilesList.getPDFFileAtIndex(widget.index);
                  PdfData newPDfData = oldPdfdata.copyWith(
                      additionDesciption: _instructionsController.text);
                  pdffilesList.replacePDFAtIndex(widget.index, newPDfData);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
