import 'package:flutter/material.dart';

import '../models/models.dart';

import 'package:accordion/accordion.dart';

class InfoAccordion extends StatefulWidget {
  final Anime anime;

  const InfoAccordion(this.anime, {Key? key}) : super(key: key);

  @override
  _InfoAccordionState createState() => _InfoAccordionState();
}

class _InfoAccordionState extends State<InfoAccordion> {
  @override
  Widget build(BuildContext context) {
    return Accordion(
      disableScrolling: true,
      maxOpenSections: 2,
      // headerTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
      // leftIcon: Icon(Icons.audiotrack, color: Colors.white),
      children: [
        if (widget.anime.demographics.isNotEmpty ||
            widget.anime.genres.isNotEmpty)
          AccordionSection(
              isOpen: false,
              leftIcon: const Icon(Icons.tag, color: Colors.white),
              header: const Text('Tags & Demographics',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              content: Wrap(
                children: [
                  ...(widget.anime.demographics
                      .map((demographic) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Chip(
                              label: Text(demographic.name),
                            ),
                          ))
                      .toList()),
                  ...(widget.anime.genres
                      .map((genre) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Chip(
                              label: Text(genre.name),
                            ),
                          ))
                      .toList()),
                ],
              )),
        if (widget.anime.synopsis.isNotEmpty)
          AccordionSection(
            isOpen: false,
            leftIcon: const Icon(Icons.book, color: Colors.white),
            header: const Text('Synopsis',
                style: TextStyle(color: Colors.white, fontSize: 17)),
            content: Text(widget.anime.synopsis),
          ),
        if (widget.anime.studios.isNotEmpty)
          AccordionSection(
            isOpen: false,
            leftIcon: const Icon(Icons.movie, color: Colors.white),
            header: const Text('Studios',
                style: TextStyle(color: Colors.white, fontSize: 17)),
            content: Wrap(
                children: widget.anime.studios
                    .map((studio) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Chip(
                            label: Text(studio.name),
                          ),
                        ))
                    .toList()),
          ),
        if (widget.anime.from != null || widget.anime.to != null)
          AccordionSection(
              isOpen: false,
              leftIcon: const Icon(Icons.calendar_today, color: Colors.white),
              header: const Text('Airing Time',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              content: Column(
                children: [
                  if (widget.anime.from != null)
                    Text('From : ' + widget.anime.from!.toLocal().toString()),
                  if (widget.anime.to != null)
                    Text('To : ' + widget.anime.to!.toLocal().toString())
                ],
              )),
        if (widget.anime.reviews.isNotEmpty)
          AccordionSection(
            isOpen: false,
            leftIcon: const Icon(Icons.reviews, color: Colors.white),
            header: const Text('Reviews',
                style: TextStyle(color: Colors.white, fontSize: 17)),
            content: SizedBox(
              height: 500,
              child: ListView(
                  children: widget.anime.reviews
                      .map(
                        (review) => ListTile(
                            leading: CircleAvatar(
                                backgroundColor: Colors.black,
                                backgroundImage: Image.memory(
                                  review.reviewer.avatar,
                                  fit: BoxFit.contain,
                                ).image),
                            title: Text(review.reviewer.nick),
                            subtitle: review.content != null
                                ? Text(review.content!)
                                : const Text("")),
                      )
                      .toList()),
            ),
          ),
      ],
    );
  }
}
