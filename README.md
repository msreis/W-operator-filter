# W-operator-filter

A set of programs to design and apply W-operator filters on noisy binary images.


parse_image.pl: creates the pair of binary ideal/observed images, as well as the
                samples of different windows screened through them.

design_W_operator.pl: given a minimum subset obtained through the execution of
                      featsel on a sample of a window of size n, designs a
                      W-operator of size n.

filter_image.pl: uses a W-operator designed using design_w_operator.pl to screen
                 the observed image of parse_image.pl, hence obtaining an image
                 that has its salt-and-pepper noise filtered.


